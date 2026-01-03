# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for document storage"
  value       = module.storage.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.bucket_arn
}

# Knowledge Base Outputs
output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = module.knowledge_base.knowledge_base_id
}

output "data_source_id" {
  description = "ID of the Knowledge Base data source"
  value       = module.knowledge_base.data_source_id
}

output "opensearch_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = module.knowledge_base.opensearch_collection_endpoint
}

# Lambda Function Outputs
output "qa_function_name" {
  description = "Name of the Q&A Lambda function"
  value       = module.lambda_functions.qa_function_name
}

output "summarize_function_name" {
  description = "Name of the summarization Lambda function"
  value       = module.lambda_functions.summarize_function_name
}

# API Gateway Outputs
output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "qa_endpoint" {
  description = "Full URL for the Q&A endpoint"
  value       = module.api_gateway.qa_endpoint
}

output "summarize_endpoint" {
  description = "Full URL for the summarization endpoint"
  value       = module.api_gateway.summarize_endpoint
}

output "api_key" {
  description = "API key for authentication (SENSITIVE - store securely)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

# Usage Instructions
output "usage_instructions" {
  description = "Quick start instructions"
  value = <<-EOT

  ========================================
  RAG Application Deployed Successfully!
  ========================================

  S3 Bucket: ${module.storage.bucket_name}
  Knowledge Base ID: ${module.knowledge_base.knowledge_base_id}
  API Endpoint: ${module.api_gateway.api_endpoint}

  Get your API key:
    terraform output -raw api_key

  Test Q&A endpoint:
    curl -X POST ${module.api_gateway.qa_endpoint} \
      -H "x-api-key: YOUR_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{"question": "What are the visa requirements for Mars?", "max_results": 5}'

  Test Summarize endpoint:
    curl -X POST ${module.api_gateway.summarize_endpoint} \
      -H "x-api-key: YOUR_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{"document_name": "Visa Requirements for Mars Travelers.pdf", "max_length": 500}'

  Demo PDFs uploaded: 4 Mars travel documents
  Sync status: Check ingestion job completion (~2-5 minutes)

  ========================================
  EOT
}