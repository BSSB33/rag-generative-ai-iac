# Demo Data: Upload sample PDF files to S3

resource "aws_s3_object" "demo_pdf_1" {
  bucket = module.storage.bucket_name
  key    = "Internal Company Travel Policies for Mars Mission.pdf"
  source = "${path.root}/s3-resources/Internal Company Travel Policies for Mars Mission.pdf"
  etag   = filemd5("${path.root}/s3-resources/Internal Company Travel Policies for Mars Mission.pdf")

  tags = {
    Type = "demo-data"
  }

  depends_on = [module.storage]
}

resource "aws_s3_object" "demo_pdf_2" {
  bucket = module.storage.bucket_name
  key    = "Itinerary Details for Mars Adventure.pdf"
  source = "${path.root}/s3-resources/Itinerary Details for Mars Adventure.pdf"
  etag   = filemd5("${path.root}/s3-resources/Itinerary Details for Mars Adventure.pdf")

  tags = {
    Type = "demo-data"
  }

  depends_on = [module.storage]
}

resource "aws_s3_object" "demo_pdf_3" {
  bucket = module.storage.bucket_name
  key    = "Travel Restrictions to Mars.pdf"
  source = "${path.root}/s3-resources/Travel Restrictions to Mars.pdf"
  etag   = filemd5("${path.root}/s3-resources/Travel Restrictions to Mars.pdf")

  tags = {
    Type = "demo-data"
  }

  depends_on = [module.storage]
}

resource "aws_s3_object" "demo_pdf_4" {
  bucket = module.storage.bucket_name
  key    = "Visa Requirements for Mars Travelers.pdf"
  source = "${path.root}/s3-resources/Visa Requirements for Mars Travelers.pdf"
  etag   = filemd5("${path.root}/s3-resources/Visa Requirements for Mars Travelers.pdf")

  tags = {
    Type = "demo-data"
  }

  depends_on = [module.storage]
}

# Trigger Knowledge Base sync after all demo files are uploaded
resource "null_resource" "trigger_kb_sync" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Triggering Knowledge Base sync for demo data..."

      aws bedrock-agent start-ingestion-job \
        --knowledge-base-id ${module.knowledge_base.knowledge_base_id} \
        --data-source-id ${module.knowledge_base.data_source_id} \
        --region ${var.region} \
        --profile vitraigabor

      echo "Sync job started! It will take 2-5 minutes to complete."
      echo "Check status with: aws bedrock-agent list-ingestion-jobs --knowledge-base-id ${module.knowledge_base.knowledge_base_id} --data-source-id ${module.knowledge_base.data_source_id} --region ${var.region} --profile vitraigabor"
    EOT
  }

  depends_on = [
    module.knowledge_base,
    aws_s3_object.demo_pdf_1,
    aws_s3_object.demo_pdf_2,
    aws_s3_object.demo_pdf_3,
    aws_s3_object.demo_pdf_4
  ]

  triggers = {
    # Re-trigger if any PDF changes
    pdf1 = filemd5("${path.root}/s3-resources/Internal Company Travel Policies for Mars Mission.pdf")
    pdf2 = filemd5("${path.root}/s3-resources/Itinerary Details for Mars Adventure.pdf")
    pdf3 = filemd5("${path.root}/s3-resources/Travel Restrictions to Mars.pdf")
    pdf4 = filemd5("${path.root}/s3-resources/Visa Requirements for Mars Travelers.pdf")
  }
}
