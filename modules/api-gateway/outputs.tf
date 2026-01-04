output "api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_key_id" {
  description = "ID of the API key"
  value       = aws_api_gateway_api_key.main.id
}

output "api_key_value" {
  description = "Value of the API key (sensitive)"
  value       = aws_api_gateway_api_key.main.value
  sensitive   = true
}

output "qa_endpoint" {
  description = "Full URL for Q&A endpoint"
  value       = "${aws_api_gateway_stage.main.invoke_url}/qa"
}

output "summarize_endpoint" {
  description = "Full URL for summarization endpoint"
  value       = "${aws_api_gateway_stage.main.invoke_url}/summarize"
}
