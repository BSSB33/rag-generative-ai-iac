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

# Usage Instructions
output "usage_instructions" {
  description = "Quick start instructions"
  value       = <<-EOT

  ========================================
  RAG Application Deployed Successfully!
  ========================================

  S3 Bucket: ${module.storage.bucket_name}
  Knowledge Base ID: ${module.knowledge_base.knowledge_base_id}

  Upload documents to S3:
    aws s3 cp your-document.pdf s3://${module.storage.bucket_name}/

  Manually trigger Knowledge Base sync:
    aws bedrock-agent start-ingestion-job \
      --knowledge-base-id ${module.knowledge_base.knowledge_base_id} \
      --data-source-id ${module.knowledge_base.data_source_id}

  ========================================
  EOT
}
