# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-exec"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM policy for Lambda to access Bedrock
resource "aws_iam_policy" "lambda_bedrock" {
  name        = "${var.project_name}-lambda-bedrock"
  description = "Allow Lambda to invoke Bedrock models and access Knowledge Base"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/eu.anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_bedrock.arn
}

# IAM policy for Lambda to access S3
resource "aws_iam_policy" "lambda_s3" {
  name        = "${var.project_name}-lambda-s3"
  description = "Allow Lambda to read from S3 documents bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}

data "archive_file" "qa" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/qa"
  output_path = "${path.root}/lambda/qa.zip"
}

data "archive_file" "summarize" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/summarize"
  output_path = "${path.root}/lambda/summarize.zip"
}

# Lambda function: Q&A
resource "aws_lambda_function" "qa" {
  filename         = data.archive_file.qa.output_path
  function_name    = "${var.project_name}-qa"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 512
  source_code_hash = data.archive_file.qa.output_base64sha256

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = var.knowledge_base_id
      MODEL_ID          = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
    }
  }

  tags = {
    Name = "${var.project_name}-qa"
  }
}

# Lambda function: Summarization
resource "aws_lambda_function" "summarize" {
  filename         = data.archive_file.summarize.output_path
  function_name    = "${var.project_name}-summarize"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 1024
  source_code_hash = data.archive_file.summarize.output_base64sha256
  layers           = [aws_lambda_layer_version.pypdf.arn]

  environment {
    variables = {
      S3_BUCKET  = var.s3_bucket_name
      MODEL_ID   = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
      MAX_TOKENS = "2000"
    }
  }

  tags = {
    Name = "${var.project_name}-summarize"
  }
}

# Lambda Layer for pypdf dependency
# Automatically install dependencies before creating the layer
resource "null_resource" "install_pypdf_dependencies" {
  triggers = {
    requirements = filemd5("${path.root}/lambda/layers/pypdf/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip3 install -t ${path.root}/lambda/layers/pypdf/python -r ${path.root}/lambda/layers/pypdf/requirements.txt --upgrade"
  }
}

data "archive_file" "pypdf_layer" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/layers/pypdf"
  output_path = "${path.root}/lambda/layers/pypdf.zip"

  depends_on = [null_resource.install_pypdf_dependencies]
}

resource "aws_lambda_layer_version" "pypdf" {
  filename            = data.archive_file.pypdf_layer.output_path
  layer_name          = "${var.project_name}-pypdf"
  source_code_hash    = data.archive_file.pypdf_layer.output_base64sha256
  compatible_runtimes = ["python3.12"]

  description = "pypdf library for PDF text extraction"
}
