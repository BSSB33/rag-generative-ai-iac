variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket containing documents"
  type        = string
}

variable "embedding_model_arn" {
  description = "ARN of Bedrock embedding model"
  type        = string
  default     = "arn:aws:bedrock:eu-west-1::foundation-model/amazon.titan-embed-text-v2:0"
}
