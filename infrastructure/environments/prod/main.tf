# Production Environment Configuration
# This file calls all modules with prod-specific variables from terraform.tfvars

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

# Data source to read global Terraform outputs
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket         = "terraform-state-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
    key            = "global/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# S3 Module (for Lambda code storage)
module "s3" {
  source = "../../modules/s3"

  environment  = var.environment
  project_name = var.project_name
  tags         = var.tags
}

# IAM Module (for roles and policies)
module "iam" {
  source = "../../modules/iam"

  aws_region                 = var.aws_region
  terraform_state_bucket_arn = data.terraform_remote_state.global.outputs.terraform_state_bucket_arn
  terraform_locks_table_arn  = data.terraform_remote_state.global.outputs.terraform_locks_table_arn
  github_repository          = var.github_repository
  github_branch              = var.github_branch
  dynamodb_table_name        = "serverless-monorepo-items-${var.environment}"
  dynamodb_table_arn         = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/serverless-monorepo-items-${var.environment}"
}

# DynamoDB Module (for application data)
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment           = var.environment
  project_name          = var.project_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  tags                  = var.tags
}

# Lambda Module (for CRUD functions)
module "lambda" {
  source = "../../modules/lambda"
  
  environment              = var.environment
  project_name             = var.project_name
  lambda_code_path         = var.lambda_code_path
  lambda_memory            = var.lambda_memory
  lambda_timeout           = var.lambda_timeout
  log_retention_days       = var.log_retention_days
  dynamodb_table_name      = module.dynamodb.table_name
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
  create_alarms            = true  # Enable CloudWatch alarms for production
  tags                     = var.tags
}

# API Gateway Module (for REST endpoints)
module "api_gateway" {
  source = "../../modules/api_gateway"
  
  environment           = var.environment
  project_name          = var.project_name
  lambda_invoke_arn     = module.lambda.function_invoke_arn
  lambda_function_name  = module.lambda.function_name
  log_retention_days    = var.log_retention_days
  tags                  = var.tags
}
