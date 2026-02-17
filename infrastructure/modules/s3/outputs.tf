# S3 Module Outputs

output "lambda_code_bucket_name" {
  description = "Name of the S3 bucket for Lambda code"
  value       = aws_s3_bucket.lambda_code.id
}

output "lambda_code_bucket_arn" {
  description = "ARN of the S3 bucket for Lambda code"
  value       = aws_s3_bucket.lambda_code.arn
}

output "lambda_code_bucket_region" {
  description = "Region of the Lambda code bucket"
  value       = aws_s3_bucket.lambda_code.region
}

output "lambda_code_logs_bucket_name" {
  description = "Name of the S3 bucket for Lambda code access logs"
  value       = aws_s3_bucket.lambda_code_logs.id
}

output "lambda_code_logs_bucket_arn" {
  description = "ARN of the S3 bucket for Lambda code access logs"
  value       = aws_s3_bucket.lambda_code_logs.arn
}
