variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "rag-app"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition = contains([
      "eu-west-1", "eu-central-1",
    ], var.region)
    error_message = "Region must support Amazon Bedrock. Supported: eu-west-1, eu-central-1"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "bedrock_model_qa" {
  description = "Bedrock model ID for question answering"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "bedrock_model_summarize" {
  description = "Bedrock model ID for summarization"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "bedrock_embedding_model" {
  description = "Bedrock embedding model ID for vector generation"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "force_destroy" {
  description = "Allow destroying S3 bucket with objects (useful for dev/testing)"
  type        = bool
  default     = true
}

variable "api_throttle_rate" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 100

  validation {
    condition     = var.api_throttle_rate >= 1 && var.api_throttle_rate <= 10000
    error_message = "API throttle rate must be between 1 and 10000."
  }
}

variable "api_throttle_burst" {
  description = "API Gateway burst limit (maximum concurrent requests)"
  type        = number
  default     = 1000

  validation {
    condition     = var.api_throttle_burst >= 1 && var.api_throttle_burst <= 10000
    error_message = "API throttle burst must be between 1 and 10000."
  }
}

variable "lambda_timeout_qa" {
  description = "Timeout for Q&A Lambda function (seconds)"
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout_qa >= 30 && var.lambda_timeout_qa <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "lambda_timeout_summarize" {
  description = "Timeout for summarization Lambda function (seconds)"
  type        = number
  default     = 120

  validation {
    condition     = var.lambda_timeout_summarize >= 30 && var.lambda_timeout_summarize <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "lambda_timeout_sync" {
  description = "Timeout for KB sync Lambda function (seconds)"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout_sync >= 10 && var.lambda_timeout_sync <= 900
    error_message = "Lambda timeout must be between 10 and 900 seconds."
  }
}

variable "lambda_memory_qa" {
  description = "Memory allocation for Q&A Lambda (MB)"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_qa >= 128 && var.lambda_memory_qa <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_memory_summarize" {
  description = "Memory allocation for summarization Lambda (MB)"
  type        = number
  default     = 1024

  validation {
    condition     = var.lambda_memory_summarize >= 128 && var.lambda_memory_summarize <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_memory_sync" {
  description = "Memory allocation for KB sync Lambda (MB)"
  type        = number
  default     = 256

  validation {
    condition     = var.lambda_memory_sync >= 128 && var.lambda_memory_sync <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "opensearch_capacity_min" {
  description = "Minimum OpenSearch Serverless capacity (OCUs)"
  type        = number
  default     = 2

  validation {
    condition     = var.opensearch_capacity_min >= 2 && var.opensearch_capacity_min <= 10
    error_message = "Minimum capacity must be between 2 and 10 OCUs."
  }
}

variable "opensearch_capacity_max" {
  description = "Maximum OpenSearch Serverless capacity (OCUs)"
  type        = number
  default     = 4

  validation {
    condition     = var.opensearch_capacity_max >= 2 && var.opensearch_capacity_max <= 10
    error_message = "Maximum capacity must be between 2 and 10 OCUs."
  }
}
