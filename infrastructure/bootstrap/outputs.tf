output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.github_oidc_arn
}

output "infrastructure_role_arn" {
  description = "ARN of the Infrastructure_Role for Terraform deployments"
  value       = aws_iam_role.infrastructure_role.arn
}

output "infrastructure_role_name" {
  description = "Name of the Infrastructure_Role"
  value       = aws_iam_role.infrastructure_role.name
}

output "lambda_deployment_role_arn" {
  description = "ARN of the Lambda_Deployment_Role for Lambda code updates"
  value       = aws_iam_role.lambda_deployment_role.arn
}

output "lambda_deployment_role_name" {
  description = "Name of the Lambda_Deployment_Role"
  value       = aws_iam_role.lambda_deployment_role.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda_Execution_Role for Lambda runtime"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda_Execution_Role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "github_actions_infrastructure_log_group" {
  description = "CloudWatch log group for infrastructure deployments"
  value       = aws_cloudwatch_log_group.github_actions_infrastructure.name
}

output "github_actions_lambda_log_group" {
  description = "CloudWatch log group for Lambda deployments"
  value       = aws_cloudwatch_log_group.github_actions_lambda.name
}
