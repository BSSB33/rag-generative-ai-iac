variable "guardrail_name" {
  description = "Name of the Bedrock guardrail"
  type        = string
}

variable "description" {
  description = "Description of the guardrail"
  type        = string
  default     = "Bedrock guardrails for content filtering and topic restrictions"
}

variable "tags" {
  description = "Tags to apply to the guardrail"
  type        = map(string)
  default     = {}
}
