# Lambda Module Outputs

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.api_handler.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api_handler.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.api_handler.invoke_arn
}

output "function_version" {
  description = "Latest version of the Lambda function"
  value       = aws_lambda_function.api_handler.version
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (with version)"
  value       = aws_lambda_function.api_handler.qualified_arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for Lambda function"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "alias_arn" {
  description = "ARN of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.api_handler_live[0].arn : null
}

output "alias_name" {
  description = "Name of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.api_handler_live[0].name : null
}

output "function_role_arn" {
  description = "ARN of the IAM role attached to the Lambda function"
  value       = var.lambda_execution_role_arn
}

output "function_timeout" {
  description = "Timeout of the Lambda function in seconds"
  value       = aws_lambda_function.api_handler.timeout
}

output "function_memory" {
  description = "Memory of the Lambda function in MB"
  value       = aws_lambda_function.api_handler.memory_size
}

output "function_runtime" {
  description = "Runtime of the Lambda function"
  value       = aws_lambda_function.api_handler.runtime
}

output "function_environment_variables" {
  description = "Environment variables of the Lambda function"
  value       = aws_lambda_function.api_handler.environment[0].variables
  sensitive   = true
}
