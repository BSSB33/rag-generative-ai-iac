output "guardrail_id" {
  description = "ID of the Bedrock guardrail"
  value       = aws_bedrock_guardrail.main.guardrail_id
}

output "guardrail_arn" {
  description = "ARN of the Bedrock guardrail"
  value       = aws_bedrock_guardrail.main.guardrail_arn
}

output "guardrail_version" {
  description = "Version of the Bedrock guardrail"
  value       = aws_bedrock_guardrail.main.version
}
