# Module: Storage (S3 bucket for documents)
module "storage" {
  source = "./modules/storage"
  project_name = var.project_name
}

# Module: Bedrock Knowledge Base with OpenSearch Serverless
module "knowledge_base" {
  source = "./modules/knowledge-base"

  project_name        = var.project_name
  s3_bucket_arn       = module.storage.bucket_arn
  embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:0"

  depends_on = [module.storage]
}
