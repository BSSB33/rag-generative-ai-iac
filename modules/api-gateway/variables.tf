variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "qa_lambda_invoke_arn" {
  description = "Invoke ARN of Q&A Lambda function"
  type        = string
}

variable "qa_lambda_name" {
  description = "Name of Q&A Lambda function"
  type        = string
}

variable "summarize_lambda_invoke_arn" {
  description = "Invoke ARN of summarization Lambda function"
  type        = string
}

variable "summarize_lambda_name" {
  description = "Name of summarization Lambda function"
  type        = string
}
