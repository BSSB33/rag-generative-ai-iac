# RAG Generative AI Application - Phase 1

A simple Retrieval Augmented Generation (RAG) application built with Terraform on AWS. 
This application aims to enable document upload, semantic search, question answering, and document summarization using Amazon Bedrock, OpenSearch Serverless, and AWS Lambda.

## Features

- **Document Upload**: Upload PDFs, text files, and documents to S3
- **Auto-Sync**: Automatic Knowledge Base synchronization on document upload
- **Question Answering**: RAG-based Q&A using semantic search
- **Document Summarization**: AI-powered document summaries
- **API Key Authentication**: Secure API access
- **Fully Terraform-Managed**: Infrastructure as Code
- **Easy Cleanup**: Complete resource destruction with `terraform destroy`

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client                                  │
│                    (Your website / API client)                  │
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
      │        Amazon Bedrock                  │
      │   - Claude 3 Sonnet (Q&A)              │
      │   - Claude 3 Haiku (Summarization)     │
      │   - Titan Embeddings (Vectors)         │
      └────┬───────────────────────────────────┘
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
