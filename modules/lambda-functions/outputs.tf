output "qa_function_arn" {
  description = "ARN of the Q&A Lambda function"
  value       = aws_lambda_function.qa.arn
}

output "qa_function_name" {
  description = "Name of the Q&A Lambda function"
  value       = aws_lambda_function.qa.function_name
}

output "qa_function_invoke_arn" {
  description = "Invoke ARN of the Q&A Lambda function"
  value       = aws_lambda_function.qa.invoke_arn
}

output "summarize_function_arn" {
  description = "ARN of the summarization Lambda function"
  value       = aws_lambda_function.summarize.arn
}

output "summarize_function_name" {
  description = "Name of the summarization Lambda function"
  value       = aws_lambda_function.summarize.function_name
}

output "summarize_function_invoke_arn" {
  description = "Invoke ARN of the summarization Lambda function"
  value       = aws_lambda_function.summarize.invoke_arn
}
