# Module: Storage (S3 bucket for documents)
module "storage" {
  source       = "./modules/storage"
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

# Module: Bedrock Guardrails
module "guardrails" {
  source = "./modules/guardrails"

  guardrail_name = "${var.project_name}-guardrails"
  description    = "Content filtering and topic restrictions for Mars travel Q&A system"

  tags = {
    Project = var.project_name
  }
}

# Module: Lambda Functions
module "lambda_functions" {
  source = "./modules/lambda-functions"

  project_name      = var.project_name
  s3_bucket_name    = module.storage.bucket_name
  s3_bucket_arn     = module.storage.bucket_arn
  knowledge_base_id = module.knowledge_base.knowledge_base_id
  data_source_id    = module.knowledge_base.data_source_id
  guardrail_id      = module.guardrails.guardrail_id
  guardrail_version = module.guardrails.guardrail_version

  depends_on = [module.knowledge_base, module.guardrails]
}

# Module: API Gateway
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name                = var.project_name
  qa_lambda_invoke_arn        = module.lambda_functions.qa_function_invoke_arn
  qa_lambda_name              = module.lambda_functions.qa_function_name
  summarize_lambda_invoke_arn = module.lambda_functions.summarize_function_invoke_arn
  summarize_lambda_name       = module.lambda_functions.summarize_function_name

  depends_on = [module.lambda_functions]
}