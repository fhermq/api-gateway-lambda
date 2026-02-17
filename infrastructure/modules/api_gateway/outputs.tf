# API Gateway Module Outputs

output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_arn" {
  description = "API Gateway REST API ARN"
  value       = aws_api_gateway_rest_api.api.arn
}

output "api_endpoint" {
  description = "API Gateway REST API endpoint URL"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.api.stage_name
}

output "stage_invoke_url" {
  description = "API Gateway stage invoke URL"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.arn
}

output "request_validator_id" {
  description = "API Gateway request validator ID"
  value       = aws_api_gateway_request_validator.all.id
}
