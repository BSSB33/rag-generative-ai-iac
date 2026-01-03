# RAG Generative AI Application - Phase 1

A simple, production-ready Retrieval Augmented Generation (RAG) application built with Terraform on AWS. This application enables document upload, semantic search, question answering, and document summarization using Amazon Bedrock, OpenSearch Serverless, and AWS Lambda.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client                                   │
│                    (Your website / API client)                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS (API Key)
                             ▼
                  ┌──────────────────────┐
                  │   API Gateway        │
                  │   - /qa              │
                  │   - /summarize       │
                  └──────────┬───────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
      ┌──────────┐   ┌──────────┐   ┌──────────┐
      │ Lambda   │   │ Lambda   │   │ Lambda   │
      │ Q&A      │   │ Summarize│   │ Sync KB  │
      └────┬─────┘   └────┬─────┘   └────┬─────┘
           │              │              │
           │              │              │ (S3 trigger)
      ┌────▼──────────────▼──────────────▼─────┐
      │        Amazon Bedrock                   │
      │   - Claude 4.5 Sonnet (Q&A)              │
      │   - Claude 4.5 Haiku (Summarization)     │
      │   - Titan Embeddings (Vectors)         │
      └────┬────────────────────────────────────┘
           │
           │ Vector Search
           ▼
      ┌─────────────────────┐
      │  Bedrock Knowledge  │
      │  Base               │
      │  ┌────────────────┐ │
      │  │  OpenSearch    │ │
      │  │  Serverless    │ │
      │  └────────────────┘ │
      └─────────────────────┘
           ▲
           │ Manual Upload
           │ (Auto-sync on upload)
      ┌────┴─────────┐
      │   S3 Bucket  │
      │   Documents  │
      └──────────────┘
```

## Features

- **Document Upload**: Upload PDFs, text files, and documents to S3
- **Auto-Sync**: Automatic Knowledge Base synchronization on document upload
- **Question Answering**: RAG-based Q&A using semantic search
- **Document Summarization**: AI-powered document summaries
- **API Key Authentication**: Secure API access
- **Fully Terraform-Managed**: Infrastructure as Code
- **Easy Cleanup**: Complete resource destruction with `terraform destroy`

## Prerequisites

### 1. AWS Account & CLI

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure AWS credentials
aws configure --profile rag-app
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 2. Terraform

```bash
# Install Terraform (macOS)
brew install terraform

# Verify installation
terraform version
# Required: >= 1.7.0
```

### 3. Enable Bedrock Models

1. Navigate to the [Amazon Bedrock console](https://console.aws.amazon.com/bedrock/home#/modelaccess)
2. Click "Enable specific models"
3. Enable the following models:
   - **Claude 3 Sonnet** (for Q&A)
   - **Claude 3 Haiku** (for summarization)
   - **Titan Embeddings V2** (for vector generation)

This process takes 2-5 minutes. Wait for all models to show "Access granted" status.

## Deployment

### Step 1: Clone and Configure

```bash
# Navigate to the project directory
cd /Users/gabor-sd/Private/projects/rag-generative-ai

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit variables (optional - defaults are sensible)
nano terraform.tfvars
```

### Step 2: Initialize Terraform

```bash
terraform init
```

This downloads required providers:
- AWS provider (~5.0)
- Creates `.terraform` directory

### Step 3: Review the Plan

```bash
terraform plan
```

Review the resources to be created:
- S3 bucket (documents storage)
- OpenSearch Serverless collection
- Bedrock Knowledge Base + Data Source
- 3 Lambda functions (sync, Q&A, summarize)
- API Gateway REST API
- IAM roles and policies
- **Total: ~25-30 resources**

### Step 4: Deploy

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time: 10-15 minutes**

Progress:
- OpenSearch Serverless collection: 5-7 min
- Bedrock Knowledge Base: 2-3 min
- Lambda functions: 1-2 min
- API Gateway: 1 min

### Step 5: Save Outputs

```bash
# View all outputs
terraform output

# Save API key (IMPORTANT!)
terraform output -raw api_key > api_key.txt

# Save API endpoint
terraform output -raw api_endpoint

# Example outputs:
# api_endpoint = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev"
# s3_bucket_name = "rag-app-documents-dev"
# knowledge_base_id = "KB123ABC456"
```

**Security Note**: Store `api_key.txt` securely and add it to `.gitignore` (already configured).

## Usage

### 1. Upload Documents

#### Via AWS Console

1. Open [S3 Console](https://console.aws.amazon.com/s3/)
2. Find bucket: `rag-app-documents-dev` (or your configured name)
3. Click "Upload"
4. Select your PDF, TXT, or DOCX files
5. Click "Upload"

#### Via AWS CLI

```bash
# Get bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Upload a document
aws s3 cp my-document.pdf s3://$BUCKET_NAME/

# Upload multiple documents
aws s3 cp documents/ s3://$BUCKET_NAME/ --recursive
```

**Supported file types:**
- `.pdf` - PDF documents
- `.txt` - Plain text files
- `.doc`, `.docx` - Microsoft Word documents

### 2. Wait for Knowledge Base Sync

After uploading, the Knowledge Base automatically syncs (S3 trigger → Lambda → Bedrock).

**Sync time:** 2-5 minutes (depending on document size and count)

**Check sync status:**

```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id) \
  --max-results 5
```

Look for `"status": "COMPLETE"` in the output.

### 3. Ask Questions (Q&A)

```bash
# Get API credentials
API_ENDPOINT=$(terraform output -raw qa_endpoint)
API_KEY=$(terraform output -raw api_key)

# Ask a question
curl -X POST "$API_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the main topic of the documents?",
    "max_results": 5
  }'
```

**Example Response:**

```json
{
  "answer": "The documents primarily discuss cloud computing and AWS services...",
  "sources": [
    {
      "document": 1,
      "score": 0.92,
      "location": {
        "s3Location": {
          "uri": "s3://rag-app-documents-dev/cloud-guide.pdf"
        }
      }
    }
  ],
  "question": "What is the main topic of the documents?",
  "documentsRetrieved": 3
}
```

### 4. Summarize Documents

```bash
# Get API credentials
API_ENDPOINT=$(terraform output -raw summarize_endpoint)
API_KEY=$(terraform output -raw api_key)

# Summarize a document
curl -X POST "$API_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "document_name": "my-document.pdf",
    "max_length": 500
  }'
```

**Example Response:**

```json
{
  "summary": "This document provides a comprehensive overview of...",
  "document_name": "my-document.pdf",
  "document_size": 15234,
  "model": "anthropic.claude-3-haiku-20240307-v1:0"
}
```

## Testing

### Quick Test Script

Create a test script `test-rag.sh`:

```bash
#!/bin/bash

# Load credentials
API_KEY=$(terraform output -raw api_key)
QA_ENDPOINT=$(terraform output -raw qa_endpoint)
SUMMARIZE_ENDPOINT=$(terraform output -raw summarize_endpoint)
BUCKET=$(terraform output -raw s3_bucket_name)

# Test 1: Upload a sample document
echo "1. Uploading sample document..."
echo "This is a test document about cloud computing and AWS services." > test-doc.txt
aws s3 cp test-doc.txt s3://$BUCKET/

# Test 2: Wait for sync
echo "2. Waiting 3 minutes for Knowledge Base sync..."
sleep 180

# Test 3: Ask a question
echo "3. Testing Q&A..."
curl -X POST "$QA_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "What is this document about?", "max_results": 3}' \
  | jq '.'

# Test 4: Summarize
echo "4. Testing summarization..."
curl -X POST "$SUMMARIZE_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"document_name": "test-doc.txt", "max_length": 200}' \
  | jq '.'

echo "All tests completed!"
```

```bash
chmod +x test-rag.sh
./test-rag.sh
```

## Cost Estimation

**Monthly costs with moderate usage:**

| Service | Usage | Estimated Cost |
|---------|-------|----------------|
| **OpenSearch Serverless** | 2-4 OCUs × 730 hours | $350-700/month |
| **Bedrock - Claude Sonnet** | 10K requests, 50K tokens/req | $50/month |
| **Bedrock - Claude Haiku** | 10K requests, 30K tokens/req | $10/month |
| **Bedrock - Titan Embeddings** | 1K documents, 10K tokens/doc | $10/month |
| **Lambda** | 20K invocations | <$1/month |
| **API Gateway** | 20K requests | <$1/month |
| **S3** | 100 GB storage, 1K requests | $3/month |
| **CloudWatch Logs** | 10 GB logs | $5/month |
| **TOTAL** | | **~$430-780/month** |

**Cost Optimization Tips:**

1. **OpenSearch**: Biggest cost driver (~85% of total)
   - Use minimum capacity (2 OCUs) for dev
   - Delete collection when not in use

2. **Lambda**: Already optimized with minimal memory

3. **Bedrock**: Pay-per-use, scales with usage
   - Haiku is 5x cheaper than Sonnet (use for simple tasks)

4. **Testing**: Destroy after testing to avoid charges

```bash
# Stop all costs
terraform destroy
```

## Monitoring

### CloudWatch Logs

```bash
# View Lambda logs (Q&A)
aws logs tail /aws/lambda/rag-app-qa-dev --follow

# View Lambda logs (Summarize)
aws logs tail /aws/lambda/rag-app-summarize-dev --follow

# View Lambda logs (Sync)
aws logs tail /aws/lambda/rag-app-sync-kb-dev --follow
```

### API Gateway Metrics

1. Open [API Gateway Console](https://console.aws.amazon.com/apigateway/)
2. Select `rag-app-api-dev`
3. Click "Dashboard" to view:
   - Request count
   - Latency (p50, p99)
   - 4XX/5XX errors
   - Integration latency

### Bedrock Knowledge Base Status

```bash
# Check Knowledge Base
aws bedrock-agent get-knowledge-base \
  --knowledge-base-id $(terraform output -raw knowledge_base_id)

# List ingestion jobs
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id)
```

## Troubleshooting

### Issue: "No relevant documents found"

**Possible causes:**
1. Knowledge Base not synced yet
2. Documents not in S3
3. Question not relevant to uploaded documents

**Solution:**
```bash
# Check if documents exist
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/

# Verify sync completed
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id)

# Manually trigger sync (if needed)
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id)
```

### Issue: "AccessDeniedException" when calling Bedrock

**Cause:** Models not enabled in Bedrock console

**Solution:**
1. Go to [Bedrock Model Access](https://console.aws.amazon.com/bedrock/home#/modelaccess)
2. Enable Claude 3 Sonnet, Claude 3 Haiku, and Titan Embeddings V2
3. Wait 2-5 minutes for activation

### Issue: API returns 403 Forbidden

**Cause:** Invalid or missing API key

**Solution:**
```bash
# Get fresh API key
terraform output -raw api_key

# Ensure header is correct
curl -X POST "..." \
  -H "x-api-key: YOUR_KEY_HERE" \  # Note: lowercase 'x-api-key'
  ...
```

### Issue: Terraform apply fails with OpenSearch errors

**Cause:** OpenSearch Serverless capacity limits in region

**Solution:**
```bash
# Try a different region
# Edit terraform.tfvars:
region = "us-west-2"  # or another supported region

terraform init -reconfigure
terraform apply
```

### Issue: Lambda timeout errors

**Cause:** Large documents or slow Bedrock response

**Solution:**
```hcl
# Edit terraform.tfvars
lambda_timeout_qa = 120        # Increase from 60
lambda_timeout_summarize = 180 # Increase from 120

# Re-apply
terraform apply
```

## Cleanup

### Delete All Resources

```bash
# Step 1: Empty S3 bucket (required for force_destroy)
aws s3 rm s3://$(terraform output -raw s3_bucket_name)/ --recursive

# Step 2: Destroy all infrastructure
terraform destroy

# Type 'yes' when prompted
```

**Cleanup time:** 5-10 minutes

**What gets deleted:**
- S3 bucket (if force_destroy = true)
- OpenSearch Serverless collection
- Bedrock Knowledge Base
- Lambda functions
- API Gateway
- IAM roles and policies
- CloudWatch log groups

**What persists:**
- CloudWatch log data (manual deletion required if desired)

### Delete CloudWatch Logs (Optional)

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/rag-app

# Delete each log group
aws logs delete-log-group --log-group-name /aws/lambda/rag-app-qa-dev
aws logs delete-log-group --log-group-name /aws/lambda/rag-app-summarize-dev
aws logs delete-log-group --log-group-name /aws/lambda/rag-app-sync-kb-dev
```

## Project Structure

```
rag-generative-ai/
├── README.md                    # This file
├── INIT_SUMMARY.md              # Deep dive into AWS samples
├── PHASE1_PLAN.md               # Implementation plan
├── main.tf                      # Main orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── providers.tf                 # Provider configuration
├── terraform.tfvars.example     # Example variables
├── terraform.tfvars             # Your variables (gitignored)
├── .gitignore                   # Git ignore rules
├── modules/
│   ├── storage/                 # S3 bucket module
│   ├── knowledge-base/          # Bedrock KB + OpenSearch
│   ├── lambda-functions/        # Lambda functions
│   └── api-gateway/             # API Gateway
└── lambda/
    ├── qa/                      # Q&A Lambda code
    │   ├── index.py
    │   └── requirements.txt
    ├── summarize/               # Summarization Lambda code
    │   ├── index.py
    │   └── requirements.txt
    └── sync-kb/                 # KB sync Lambda code
        ├── index.py
        └── requirements.txt
```

## Next Steps (Future Phases)

### Phase 2: Enhanced Features
- Document upload API endpoint
- Cost controls and quotas
- Multi-document Q&A with citations
- Document metadata extraction

### Phase 3: Production Hardening
- Bedrock Guardrails for content safety
- CloudWatch dashboards and alarms
- API request logging and analytics
- Backup and disaster recovery

### Phase 4: Website Integration
- React/JavaScript SDK
- Embed in resume website
- Graceful degradation
- Custom styling

## Support

For issues, questions, or contributions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
3. Check [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
4. Open an issue in the repository

## License

MIT-0 (see LICENSE file)

## Security

- Never commit `terraform.tfvars` or `api_key.txt` to version control
- Rotate API keys regularly
- Use AWS IAM best practices
- Enable CloudTrail for audit logging
- Review IAM policies for least privilege

---

**Happy building! 🚀**
