"""
Lambda function for document summarization
Uses Bedrock Claude to generate summaries of uploaded documents
"""
import json
import os
import logging
import boto3
import io
from botocore.exceptions import ClientError
from pypdf import PdfReader

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

# Environment variables
S3_BUCKET = os.environ.get('S3_BUCKET')
MODEL_ID = os.environ.get('MODEL_ID', 'eu.anthropic.claude-haiku-4-5-20251001-v1:0')
MAX_TOKENS = int(os.environ.get('MAX_TOKENS', '2000'))


def lambda_handler(event, context):
    """
    Generate a summary of a document from S3

    Args:
        event: API Gateway event with document_name in body
        context: Lambda context

    Returns:
        dict: Response with summary
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # Validate environment variables
    if not S3_BUCKET:
        error_msg = "Missing required environment variable: S3_BUCKET"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }

    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        document_name = body.get('document_name', '').strip()
        max_length = int(body.get('max_length', 500))

        if not document_name:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'document_name is required'
                })
            }

        logger.info(f"Summarizing document: {document_name}, Max length: {max_length}")

        # Retrieve document from S3
        logger.info(f"Fetching document from S3: s3://{S3_BUCKET}/{document_name}")

        try:
            s3_response = s3_client.get_object(
                Bucket=S3_BUCKET,
                Key=document_name
            )
            document_bytes = s3_response['Body'].read()

            # Extract text based on file type
            if document_name.lower().endswith('.pdf'):
                logger.info("Processing PDF file")
                pdf_file = io.BytesIO(document_bytes)
                pdf_reader = PdfReader(pdf_file)

                # Extract text from all pages
                text_parts = []
                for page_num, page in enumerate(pdf_reader.pages, 1):
                    text = page.extract_text()
                    if text.strip():
                        text_parts.append(text)

                document_content = '\n\n'.join(text_parts)

                if not document_content.strip():
                    return {
                        'statusCode': 400,
                        'headers': {
                            'Content-Type': 'application/json',
                            'Access-Control-Allow-Origin': '*'
                        },
                        'body': json.dumps({
                            'error': 'Could not extract text from PDF'
                        })
                    }
            else:
                # Assume plain text file
                logger.info("Processing text file")
                document_content = document_bytes.decode('utf-8')

        except s3_client.exceptions.NoSuchKey:
            logger.error(f"Document not found: {document_name}")
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'Document not found: {document_name}'
                })
            }

        # Check document size
        doc_size = len(document_content)
        logger.info(f"Document size: {doc_size} characters")

        if doc_size == 0:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Document is empty'
                })
            }

        # Truncate if document is too large (100k chars limit)
        if doc_size > 100000:
            logger.warning(f"Document too large ({doc_size} chars), truncating to 100k")
            document_content = document_content[:100000] + "\n\n[Document truncated...]"

        # Generate summary using Claude
        prompt = f"""Please provide a clear and concise summary of the following document.
The summary should be approximately {max_length} words and capture the main points, key findings, and important details.

Document:
{document_content}

Summary:"""

        logger.info(f"Generating summary with model: {MODEL_ID}")

        bedrock_response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": MAX_TOKENS,
                "temperature": 0.5,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )

        response_body = json.loads(bedrock_response['body'].read())
        summary = response_body['content'][0]['text']

        logger.info("Summary generated successfully")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'summary': summary,
                'document_name': document_name,
                'document_size': doc_size,
                'model': MODEL_ID
            })
        }

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in request body: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"AWS ClientError: {error_code} - {error_message}")

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'{error_code}: {error_message}'
            })
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'Internal server error: {str(e)}'
            })
        }
