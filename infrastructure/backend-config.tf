# Shared Backend Configuration
# This file defines the S3 backend with DynamoDB locking
# Used by all environments via -backend-config flags during terraform init

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration is provided via -backend-config flags during init
    # Example:
    # terraform init \
    #   -backend-config="bucket=terraform-state-123456789-us-east-1" \
    #   -backend-config="key=dev/terraform.tfstate" \
    #   -backend-config="region=us-east-1" \
    #   -backend-config="dynamodb_table=terraform-locks" \
    #   -backend-config="encrypt=true"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
