# Staging Environment Outputs

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# S3 Module Outputs
output "lambda_code_bucket_name" {
  description = "S3 bucket name for Lambda code"
  value       = module.s3.lambda_code_bucket_name
}

output "lambda_code_bucket_arn" {
  description = "S3 bucket ARN for Lambda code"
  value       = module.s3.lambda_code_bucket_arn
}

# IAM Module Outputs
output "infrastructure_role_arn" {
  description = "ARN of the Infrastructure Role for Terraform"
  value       = module.iam.infrastructure_role_arn
}

output "infrastructure_role_name" {
  description = "Name of the Infrastructure Role"
  value       = module.iam.infrastructure_role_name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda Execution Role"
  value       = module.iam.lambda_execution_role_arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda Execution Role"
  value       = module.iam.lambda_execution_role_name
}

output "lambda_deployment_role_arn" {
  description = "ARN of the Lambda Deployment Role for GitHub Actions"
  value       = module.iam.lambda_deployment_role_arn
}

output "lambda_deployment_role_name" {
  description = "Name of the Lambda Deployment Role"
  value       = module.iam.lambda_deployment_role_name
}

# DynamoDB Module Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB items table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB items table"
  value       = module.dynamodb.table_arn
}

output "dynamodb_table_stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = module.dynamodb.table_stream_arn
}

output "dynamodb_gsi_name" {
  description = "Name of the status-index GSI"
  value       = module.dynamodb.gsi_name
}

# Lambda Module Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

# API Gateway Module Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.stage_invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}
