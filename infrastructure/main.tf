# Shared Main Configuration - Calls all modules
# This file is used by all environments
# Environment-specific variables are provided via terraform.tfvars

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

# Modules will be called here as they are created:

# S3 Module (for Lambda code storage)
module "s3" {
  source = "./modules/s3"

  environment  = var.environment
  project_name = var.project_name
  tags         = var.tags
}

# IAM Module (for roles and policies)
module "iam" {
  source = "./modules/iam"

  aws_region                 = var.aws_region
  terraform_state_bucket_arn = data.terraform_remote_state.global.outputs.terraform_state_bucket_arn
  terraform_locks_table_arn  = data.terraform_remote_state.global.outputs.terraform_locks_table_arn
  github_repository          = var.github_repository
  github_branch              = var.github_branch
}

# DynamoDB Module (for application data)
module "dynamodb" {
  source = "./modules/dynamodb"

  environment           = var.environment
  project_name          = var.project_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  tags                  = var.tags
}

# Lambda Module (for CRUD functions)
# module "lambda" {
#   source = "./modules/lambda"
#   
#   environment              = var.environment
#   project_name             = var.project_name
#   lambda_memory            = var.lambda_memory
#   lambda_timeout           = var.lambda_timeout
#   log_retention_days       = var.log_retention_days
#   dynamodb_table_name      = module.dynamodb.table_name
#   lambda_execution_role_arn = module.iam.lambda_execution_role_arn
#   tags                     = var.tags
# }

# API Gateway Module (for REST endpoints)
# module "api_gateway" {
#   source = "./modules/api_gateway"
#   
#   environment                    = var.environment
#   project_name                   = var.project_name
#   lambda_function_arn            = module.lambda.function_arn
#   lambda_function_name           = module.lambda.function_name
#   enable_cors                    = var.enable_cors
#   cors_allowed_origins           = var.cors_allowed_origins
#   api_gateway_throttle_settings  = var.api_gateway_throttle_settings
#   log_retention_days             = var.log_retention_days
#   tags                           = var.tags
# }
