variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for documents"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for documents"
  type        = string
}

variable "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  type        = string
}

variable "data_source_id" {
  description = "Knowledge Base data source ID"
  type        = string
}

variable "guardrail_id" {
  description = "Bedrock Guardrail ID"
  type        = string
}

variable "guardrail_version" {
  description = "Bedrock Guardrail version"
  type        = string
}