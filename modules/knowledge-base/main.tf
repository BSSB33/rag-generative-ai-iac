# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# OpenSearch Serverless encryption policy
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.project_name}-encryption"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.project_name}-kb"
        ]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

# OpenSearch Serverless network policy
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-network"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${var.project_name}-kb"
          ]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch Serverless data access policy
resource "aws_opensearchserverless_access_policy" "data_access" {
  name = "${var.project_name}-data-access"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${var.project_name}-kb"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        },
        {
          Resource = [
            "index/${var.project_name}-kb/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        }
      ]
      Principal = [
        aws_iam_role.bedrock_kb.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}

# OpenSearch Serverless collection
resource "aws_opensearchserverless_collection" "kb" {
  name = "${var.project_name}-kb"
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]

  tags = {
    Name = "${var.project_name}-kb"
  }
}

# Create OpenSearch index required by Bedrock Knowledge Base
resource "null_resource" "create_index" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing opensearch-py if needed..."
      pip3 install opensearch-py -q 2>/dev/null || true

      echo "Waiting for OpenSearch collection to be ready..."
      sleep 30

      python3 -c "
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth

# Get credentials from environment variables
session = boto3.Session(region_name='${data.aws_region.current.name}')
credentials = session.get_credentials()
auth = AWSV4SignerAuth(credentials, '${data.aws_region.current.name}', 'aoss')

# Extract host from endpoint
endpoint = '${aws_opensearchserverless_collection.kb.collection_endpoint}'
host = endpoint.replace('https://', '').replace('http://', '')

# OpenSearch client
client = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
    timeout=30
)

# Index configuration
index_body = {
    'settings': {
        'index.knn': True
    },
    'mappings': {
        'properties': {
            'bedrock-knowledge-base-default-vector': {
                'type': 'knn_vector',
                'dimension': 1024,
                'method': {
                    'name': 'hnsw',
                    'engine': 'faiss'
                }
            },
            'AMAZON_BEDROCK_TEXT_CHUNK': {
                'type': 'text'
            },
            'AMAZON_BEDROCK_METADATA': {
                'type': 'text',
                'index': False
            }
        }
    }
}

# Create index
try:
    response = client.indices.create(index='bedrock-knowledge-base-index', body=index_body)
    print('Index created successfully:', response)
except Exception as e:
    if 'resource_already_exists' in str(e).lower():
        print('Index already exists (this is fine)')
    else:
        print('Error creating index:', e)
        raise
"
    EOT
  }

  depends_on = [
    aws_opensearchserverless_collection.kb,
    aws_opensearchserverless_access_policy.data_access
  ]

  triggers = {
    collection_id = aws_opensearchserverless_collection.kb.id
  }
}

# IAM role for Bedrock Knowledge Base
resource "aws_iam_role" "bedrock_kb" {
  name = "${var.project_name}-bedrock-kb"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-bedrock-kb"
  }
}

# IAM policy for Bedrock KB to access S3
resource "aws_iam_policy" "bedrock_kb_s3" {
  name        = "${var.project_name}-bedrock-kb-s3"
  description = "Allow Bedrock KB to access S3 bucket"

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

resource "aws_iam_role_policy_attachment" "bedrock_kb_s3" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_s3.arn
}

# IAM policy for Bedrock KB to access OpenSearch
resource "aws_iam_policy" "bedrock_kb_aoss" {
  name        = "${var.project_name}-bedrock-kb-aoss"
  description = "Allow Bedrock KB to access OpenSearch Serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.kb.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_kb_aoss" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_aoss.arn
}

# IAM policy for Bedrock KB to invoke embedding model
resource "aws_iam_policy" "bedrock_kb_model" {
  name        = "${var.project_name}-bedrock-kb-model"
  description = "Allow Bedrock KB to invoke embedding model"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = var.embedding_model_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_kb_model" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_model.arn
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "kb" {
  name     = "${var.project_name}-kb"
  role_arn = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb.arn
      vector_index_name = "bedrock-knowledge-base-index"
      field_mapping {
        metadata_field = "AMAZON_BEDROCK_METADATA"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        vector_field   = "bedrock-knowledge-base-default-vector"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.bedrock_kb_s3,
    aws_iam_role_policy_attachment.bedrock_kb_aoss,
    aws_iam_role_policy_attachment.bedrock_kb_model,
    aws_opensearchserverless_access_policy.data_access,
    null_resource.create_index
  ]

  tags = {
    Name = "${var.project_name}-kb"
  }
}

# Bedrock Knowledge Base Data Source
resource "aws_bedrockagent_data_source" "kb" {
  name              = "${var.project_name}-kb-datasource"
  knowledge_base_id = aws_bedrockagent_knowledge_base.kb.id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.s3_bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
