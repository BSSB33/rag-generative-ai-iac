# RAG Generative AI with AWS Bedrock

A simplified RAG (Retrieval Augmented Generation) application using AWS Bedrock Knowledge Base, OpenSearch Serverless, Lambda Functions, and API Gateway - all managed with Terraform.

## Architecture

```
┌─────────────────────────────────────┐
│   Client (Your Website)             │
└──────────────┬──────────────────────┘
               │ HTTPS (API Key)
               ▼
    ┌──────────────────────┐
    │   API Gateway        │
    │   - /qa              │
    │   - /summarize       │
    └──────────┬───────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
   ┌─────────┐   ┌──────────┐
   │ Lambda  │   │ Lambda   │
   │ Q&A     │   │ Summarize│
   └────┬────┘   └────┬─────┘
        │             │
        └──────┬──────┘
               ▼
      ┌────────────────────┐
      │  Amazon Bedrock    │
      │  - Claude Sonnet   │
      │  - Claude Haiku    │
      │  - Titan Embeddings│
      └─────────┬──────────┘
                │
                ▼
   ┌─────────────────────────┐
   │ Bedrock Knowledge Base  │
   │  ┌──────────────────┐   │
   │  │ OpenSearch       │   │
   │  │ Serverless       │   │
   │  └──────────────────┘   │
   └──────────┬──────────────┘
              │
              ▼
      ┌───────────────┐
      │  S3 Bucket    │
      │  (Documents)  │
      └───────────────┘
```

## Features

- **S3 Document Storage** - Upload PDFs, TXT, DOCX files
- **OpenSearch Serverless** - Vector search with KNN
- **Bedrock Knowledge Base** - Automated document chunking and embedding
- **Lambda Functions** - Q&A and summarization endpoints
- **API Gateway** - REST API with API key authentication
- **Demo Data** - 4 sample Mars travel PDFs auto-uploaded
- **One-click Deployment** - Everything managed by Terraform
- **Simple & Clean** - Minimal variables, sensible defaults

## Prerequisites

1. **AWS CLI** configured with SSO
2. **Terraform** >= 1.0
3. **Python 3** with pip (for OpenSearch index creation)
4. **Bedrock Model Access** - Enable these models in AWS Console:
   - Claude 4.5 Sonnet (Q&A)
   - Claude 4.5 Haiku (Summarization)
   - Titan Embeddings V2 (Vector generation)

## Quick Start

### 1. Configure AWS SSO

```bash
aws sso login --profile vitraigabor
eval $(aws configure export-credentials --profile vitraigabor --format env)
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform apply
```

**What gets deployed:**
- S3 bucket for documents
- OpenSearch Serverless collection with vector index
- Bedrock Knowledge Base + data source
- 2 Lambda functions (qa, summarize)
- API Gateway with API key
- 4 demo PDFs uploaded automatically
- Initial Knowledge Base sync triggered

**Deployment time:** ~12-15 minutes
- OpenSearch collection: 3-4 min
- Bedrock Knowledge Base: 2-3 min
- Lambda functions: 1-2 min
- API Gateway: 1 min
- Demo data upload + sync: 3-5 min

### 3. Get Your API Credentials

```bash
# Get API key (store this securely!)
terraform output -raw api_key

# Get API endpoint
terraform output api_endpoint
```

### 4. Test the API

**Q&A:**
```bash
API_KEY=$(terraform output -raw api_key)
QA_ENDPOINT=$(terraform output -raw qa_endpoint)

curl -X POST "$QA_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the visa requirements for traveling to Mars?",
    "max_results": 5
  }'
```

**Summarize:**
```bash
SUMMARIZE_ENDPOINT=$(terraform output -raw summarize_endpoint)

curl -X POST "$SUMMARIZE_ENDPOINT" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "document_name": "Visa Requirements for Mars Travelers.pdf",
    "max_length": 500
  }'
```

## Project Structure

```
.
├── main.tf                  # Module orchestration
├── demo-data.tf             # Demo PDF uploads + sync trigger
├── variables.tf             # Input variables (project_name, region)
├── outputs.tf               # API endpoints, credentials, usage info
├── providers.tf             # AWS provider with default tags
├── backend.tf               # S3 backend configuration
├── modules/
│   ├── storage/            # S3 bucket module
│   ├── knowledge-base/     # OpenSearch + Bedrock KB + index creation
│   ├── lambda-functions/   # Lambda functions module
│   └── api-gateway/        # API Gateway with API key
├── lambda/
│   ├── qa/                 # Q&A Lambda code
│   └── summarize/          # Summarization Lambda code
└── s3-resources/           # Demo PDF files
    ├── Internal Company Travel Policies for Mars Mission.pdf
    ├── Itinerary Details for Mars Adventure.pdf
    ├── Travel Restrictions to Mars.pdf
    └── Visa Requirements for Mars Travelers.pdf
```

## Adding Your Own Documents

### Upload files to S3:
```bash
BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 cp your-document.pdf s3://$BUCKET/ --profile vitraigabor
```

### Trigger sync manually:
```bash
KB_ID=$(terraform output -raw knowledge_base_id)
DS_ID=$(terraform output -raw data_source_id)

aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS_ID \
  --region eu-west-1 \
  --profile vitraigabor
```

### Check sync status:
```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS_ID \
  --region eu-west-1 \
  --profile vitraigabor \
  --max-results 5
```

## Integrating with Your Website

The API is CORS-enabled and ready for your Cloud Resume Challenge website:

```javascript
// JavaScript example
const apiKey = 'YOUR_API_KEY';
const qaEndpoint = 'https://your-api-id.execute-api.eu-west-1.amazonaws.com/prod/qa';

async function askQuestion(question) {
  const response = await fetch(qaEndpoint, {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      question: question,
      max_results: 5
    })
  });

  return await response.json();
}

// Usage
const answer = await askQuestion('What are the travel policies?');
console.log(answer);
```

## Cost Estimate

**Monthly costs with demo usage:**

| Service | Usage | Cost |
|---------|-------|------|
| OpenSearch Serverless | 2 OCUs × 730 hours | ~$350/month |
| Bedrock Claude Sonnet | 100 queries, 50K tokens/query | ~$5/month |
| Bedrock Claude Haiku | 100 queries, 30K tokens/query | ~$2/month |
| Bedrock Titan Embeddings | 4 documents, 10K tokens/doc | <$1/month |
| Lambda | 200 invocations | <$1/month |
| API Gateway | 200 requests | <$1/month |
| S3 | 4 PDFs, minimal requests | <$1/month |
| **TOTAL** | | **~$360/month** |

**Cost optimization:**
- OpenSearch Serverless is ~95% of costs
- Destroy when not in use: `terraform destroy`
- For production, consider OpenSearch managed clusters (cheaper at scale)

## Cleanup

```bash
terraform destroy
```

All resources will be deleted. S3 bucket has `force_destroy = true` so it deletes even with documents inside.

## Future Improvements

### Debounced Auto-Sync (Production-Ready)

For production use with frequent document uploads, implement intelligent auto-sync:

**Current approach:**
- Demo PDFs uploaded once by Terraform
- Manual sync triggered automatically after upload
- Additional documents require manual sync trigger
- Simple, predictable, cost-effective for demos

**Production approach - Debounced Auto-Sync:**

```
Upload file(s) → S3 Event → SQS Queue
                              ↓
                     Lambda (triggered every 5 min via EventBridge)
                              ↓
                     Check queue + sync status
                              ↓
                     Batch sync if needed
```

**Benefits:**
- **Efficient** - One sync job for multiple file uploads
- **Cost-effective** - Fewer Bedrock ingestion jobs
- **Smart batching** - Waits for upload bursts to complete
- **Prevents throttling** - No concurrent sync jobs
- **Scalable** - Handles high upload volumes

**Why debouncing matters:**
- Upload 100 files → **One sync** (not 100!)
- Bedrock scans entire bucket anyway
- 5-minute delay acceptable for most use cases
- Dramatically reduces costs and API calls

**Implementation outline:**

1. **S3 Event Notifications** → SQS Queue (not direct Lambda trigger)
2. **EventBridge Schedule** → Triggers Lambda every 5 minutes
3. **Lambda logic:**
   ```python
   # Check if messages in SQS queue
   # Check if sync job already running
   # If queue has items AND no active sync → trigger one sync
   # Clear queue after sync starts
   ```

**Alternative: Event-driven batching**
- Use SQS batch window (wait 5 minutes for more messages)
- Lambda triggered only when batch window closes
- Even simpler implementation

**Cost comparison:**
- Without debouncing: 100 uploads = 100 syncs = $$$
- With debouncing: 100 uploads = 1 sync = $

### Other Production Enhancements

- **Multi-environment** - Dev/staging/prod separation with workspaces
- **CI/CD Pipeline** - GitHub Actions for automated deployments
- **CloudWatch Dashboards** - Monitoring, metrics, and alerting
- **Cost Alerts** - Budget notifications and anomaly detection
- **Backup Strategy** - S3 versioning and cross-region replication
- **Rate Limiting** - Per-user API quotas
- **Authentication** - Cognito or Auth0 integration (beyond API keys)
- **Caching** - CloudFront + Lambda@Edge for response caching
- **Observability** - X-Ray tracing for debugging

## Tags

All resources are tagged with:
- `Project` - Project name
- `ManagedBy` - "Terraform"
- `cloud-resume` - "true"

## Troubleshooting

**Issue: API returns 403 Forbidden**
- Ensure you're using the correct API key header: `x-api-key`
- Get fresh API key: `terraform output -raw api_key`

**Issue: "No relevant documents found"**
- Check sync status: See "Check sync status" command above
- Wait 2-5 minutes for ingestion to complete
- Verify documents uploaded to S3: `aws s3 ls s3://$(terraform output -raw s3_bucket_name)/`

**Issue: OpenSearch index creation fails**
- Run: `pip3 install opensearch-py`
- Re-run: `terraform apply`

## License

MIT

## Support

For questions or issues:
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [OpenSearch Serverless Guide](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless.html)
