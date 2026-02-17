# IAM Module Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  type        = string
}

variable "terraform_locks_table_arn" {
  description = "ARN of the Terraform locks DynamoDB table"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$", var.github_repository))
    error_message = "GitHub repository must be in format 'owner/repo'."
  }
}

variable "github_branch" {
  description = "GitHub branch that can assume the roles"
  type        = string
  default     = "main"
  validation {
    condition     = length(var.github_branch) > 0
    error_message = "GitHub branch cannot be empty."
  }
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Lambda to access"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}
