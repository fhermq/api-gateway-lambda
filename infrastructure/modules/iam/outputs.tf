# IAM Module Outputs

output "infrastructure_role_arn" {
  description = "ARN of the Infrastructure Role for Terraform"
  value       = aws_iam_role.infrastructure_role.arn
}

output "infrastructure_role_name" {
  description = "Name of the Infrastructure Role"
  value       = aws_iam_role.infrastructure_role.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda Execution Role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda Execution Role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lambda_deployment_role_arn" {
  description = "ARN of the Lambda Deployment Role for GitHub Actions"
  value       = aws_iam_role.lambda_deployment_role.arn
}

output "lambda_deployment_role_name" {
  description = "Name of the Lambda Deployment Role"
  value       = aws_iam_role.lambda_deployment_role.name
}
