# Global Resources - Terraform State Backend
# This configuration creates the S3 bucket and DynamoDB table for Terraform state management
# These resources are created ONCE and shared by all environments

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Note: This configuration uses local state initially
  # After creation, migrate to the S3 backend created by this configuration
}

provider "aws" {
  region = var.aws_region
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = {
    Name        = "terraform-state"
    Environment = "global"
    Purpose     = "Terraform state storage"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy to clean up old state versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-state-versions"
    status = "Enabled"
    filter {}

    # Keep only the last 7 days of old versions
    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    # Remove delete markers for deleted state files
    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Enable server-side encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging for the S3 bucket
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "terraform-state-logs/"
}

# S3 Bucket for storing access logs
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "terraform-state-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = {
    Name        = "terraform-state-logs"
    Environment = "global"
    Purpose     = "Terraform state access logs"
    ManagedBy   = "Terraform"
  }
}

# Block public access to the logs bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on the logs bucket
resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for logs bucket - delete old logs after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    filter {}

    # Delete logs older than 30 days
    expiration {
      days = 30
    }

    # Delete old versions after 7 days
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "global"
    Purpose     = "Terraform state locking"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for Terraform operations
resource "aws_cloudwatch_log_group" "terraform" {
  name              = "/aws/terraform/operations"
  retention_in_days = 30

  tags = {
    Name        = "terraform-logs"
    Environment = "global"
    Purpose     = "Terraform operation logs"
    ManagedBy   = "Terraform"
  }
}
