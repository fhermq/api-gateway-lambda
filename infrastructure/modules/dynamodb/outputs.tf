# DynamoDB Module Outputs

output "table_name" {
  description = "Name of the DynamoDB items table"
  value       = aws_dynamodb_table.items.name
}

output "table_arn" {
  description = "ARN of the DynamoDB items table"
  value       = aws_dynamodb_table.items.arn
}

output "table_id" {
  description = "ID of the DynamoDB items table"
  value       = aws_dynamodb_table.items.id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.items.stream_arn
}

output "table_stream_label" {
  description = "Label of the DynamoDB stream"
  value       = aws_dynamodb_table.items.stream_label
}

output "gsi_name" {
  description = "Name of the status-index GSI"
  value       = "status-index"
}

output "table_region" {
  description = "AWS region where the table is created"
  value       = data.aws_region.current.name
}

output "table_account_id" {
  description = "AWS account ID where the table is created"
  value       = data.aws_caller_identity.current.account_id
}
