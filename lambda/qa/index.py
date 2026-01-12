"""
Lambda function for RAG-based question answering
Uses Bedrock Knowledge Base for retrieval and Claude for generation
"""
import json
import os
import logging
import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')
bedrock_runtime = boto3.client('bedrock-runtime')

# Environment variables
KNOWLEDGE_BASE_ID = os.environ.get('KNOWLEDGE_BASE_ID')
MODEL_ID = os.environ.get('MODEL_ID', 'eu.anthropic.claude-sonnet-4-5-20250929-v1:0')
GUARDRAIL_ID = os.environ.get('GUARDRAIL_ID')
GUARDRAIL_VERSION = os.environ.get('GUARDRAIL_VERSION')


def lambda_handler(event, context):
    """
    Answer questions using RAG (Retrieval Augmented Generation)

    Args:
        event: API Gateway event with question in body
        context: Lambda context

    Returns:
        dict: Response with answer and sources
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # Validate environment variables
    if not KNOWLEDGE_BASE_ID:
        error_msg = "Missing required environment variable: KNOWLEDGE_BASE_ID"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }

    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        question = body.get('question', '').strip()
        max_results = int(body.get('max_results', 5))

        if not question:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Question is required'
                })
            }

        logger.info(f"Question: {question}, Max results: {max_results}")

        # Retrieve relevant documents from Knowledge Base
        logger.info(f"Querying Knowledge Base: {KNOWLEDGE_BASE_ID}")

        retrieve_response = bedrock_agent_runtime.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
            retrievalQuery={
                'text': question
            },
            retrievalConfiguration={
                'vectorSearchConfiguration': {
                    'numberOfResults': max_results
                }
            }
        )

        # Extract retrieved documents
        retrieval_results = retrieve_response.get('retrievalResults', [])

        if not retrieval_results:
            logger.warning("No relevant documents found")
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'answer': 'I could not find any relevant information in the knowledge base to answer this question.',
                    'sources': [],
                    'question': question
                })
            }

        # Build context from retrieved documents
        context_parts = []
        sources = []

        for idx, result in enumerate(retrieval_results, 1):
            content = result.get('content', {}).get('text', '')
            score = result.get('score', 0)
            location = result.get('location', {})

            if content:
                context_parts.append(f"Document {idx} (relevance: {score:.2f}):\n{content}")
                sources.append({
                    'document': idx,
                    'score': score,
                    'location': location
                })

        context = "\n\n".join(context_parts)
        logger.info(f"Retrieved {len(context_parts)} documents")

        # Generate answer using Claude
        prompt = f"""You are a helpful AI assistant. Answer the question based on the provided context.

Context:
{context}

Question: {question}

Please provide a clear, concise answer based on the context above. If the context doesn't contain enough information to answer the question, say so."""

        logger.info(f"Generating answer with model: {MODEL_ID}")

        # Prepare invoke_model parameters
        invoke_params = {
            'modelId': MODEL_ID,
            'body': json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "temperature": 0.7,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        }

        # Add guardrail if configured
        if GUARDRAIL_ID and GUARDRAIL_VERSION:
            invoke_params['guardrailIdentifier'] = GUARDRAIL_ID
            invoke_params['guardrailVersion'] = GUARDRAIL_VERSION
            logger.info(f"Applying guardrail: {GUARDRAIL_ID} v{GUARDRAIL_VERSION}")

        bedrock_response = bedrock_runtime.invoke_model(**invoke_params)

        response_body = json.loads(bedrock_response['body'].read())
        answer = response_body['content'][0]['text']

        logger.info("Answer generated successfully")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'answer': answer,
                'sources': sources,
                'question': question,
                'documentsRetrieved': len(retrieval_results)
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
