output "bucket_name" {
  description = "Name of the S3 bucket for documents"
  value       = aws_s3_bucket.documents.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.documents.arn
}

output "kb_s3_access_policy_arn" {
  description = "ARN of IAM policy for KB S3 access"
  value       = aws_iam_policy.kb_s3_access.arn
}
