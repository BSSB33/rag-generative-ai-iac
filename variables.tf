variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "rag-demo"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}
