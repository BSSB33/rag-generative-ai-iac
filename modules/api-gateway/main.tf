# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "RAG Application API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Resource: /qa
resource "aws_api_gateway_resource" "qa" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "qa"
}

# API Gateway Method: POST /qa
resource "aws_api_gateway_method" "qa_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.qa.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# API Gateway Integration: POST /qa -> Lambda
resource "aws_api_gateway_integration" "qa_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.qa.id
  http_method             = aws_api_gateway_method.qa_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.qa_lambda_invoke_arn
}

# Lambda permission for API Gateway to invoke Q&A function
resource "aws_lambda_permission" "qa_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.qa_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Resource: /summarize
resource "aws_api_gateway_resource" "summarize" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "summarize"
}

# API Gateway Method: POST /summarize
resource "aws_api_gateway_method" "summarize_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.summarize.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# API Gateway Integration: POST /summarize -> Lambda
resource "aws_api_gateway_integration" "summarize_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.summarize.id
  http_method             = aws_api_gateway_method.summarize_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.summarize_lambda_invoke_arn
}

# Lambda permission for API Gateway to invoke summarization function
resource "aws_lambda_permission" "summarize_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.summarize_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.qa.id,
      aws_api_gateway_method.qa_post.id,
      aws_api_gateway_integration.qa_post.id,
      aws_api_gateway_resource.summarize.id,
      aws_api_gateway_method.summarize_post.id,
      aws_api_gateway_integration.summarize_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.qa_post,
    aws_api_gateway_integration.summarize_post
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

# API Gateway Method Settings (throttling)
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 1000
    # CloudWatch logging disabled to avoid account-level IAM role setup and reduce costs
    # logging_level          = "INFO"
    # data_trace_enabled     = true
    # metrics_enabled        = true
  }
}

# API Gateway API Key
resource "aws_api_gateway_api_key" "main" {
  name    = "${var.project_name}-api-key"
  enabled = true

  tags = {
    Name = "${var.project_name}-api-key"
  }
}

# API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "main" {
  name = "${var.project_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    rate_limit  = 100
    burst_limit = 1000
  }

  tags = {
    Name = "${var.project_name}-usage-plan"
  }
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
