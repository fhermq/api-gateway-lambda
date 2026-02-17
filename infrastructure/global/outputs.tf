# Global Outputs - Terraform State Backend Information

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_logs_bucket_name" {
  description = "Name of the S3 bucket for Terraform state access logs"
  value       = aws_s3_bucket.terraform_state_logs.id
}

output "terraform_locks_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "terraform_locks_table_arn" {
  description = "ARN of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "terraform_log_group_name" {
  description = "CloudWatch Log Group for Terraform operations"
  value       = aws_cloudwatch_log_group.terraform.name
}

output "backend_config_command" {
  description = "Command to use for terraform init with backend configuration"
  value       = "terraform init -backend-config=\"bucket=${aws_s3_bucket.terraform_state.id}\" -backend-config=\"key={environment}/terraform.tfstate\" -backend-config=\"region=${data.aws_region.current.name}\" -backend-config=\"dynamodb_table=${aws_dynamodb_table.terraform_locks.name}\" -backend-config=\"encrypt=true\""
}
