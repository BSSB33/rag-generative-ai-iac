# Terraform S3 Backend Configuration
terraform {
  backend "s3" {
    bucket         = "vitraiaws-terraform-states"
    key            = "rag-generative-ai/terraform.tfstate"
    region         = "eu-west-1"
    profile        = "vitraigabor"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
