terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# GitHub OIDC Provider (data source to use existing or create new)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create OIDC provider only if it doesn't exist
resource "aws_iam_openid_connect_provider" "github" {
  count           = try(data.aws_iam_openid_connect_provider.github.arn, null) == null ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "github-oidc-provider"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

# Use existing or newly created OIDC provider
locals {
  github_oidc_arn = try(data.aws_iam_openid_connect_provider.github.arn, aws_iam_openid_connect_provider.github[0].arn)
}

# Infrastructure Role (for Terraform deployments)
resource "aws_iam_role" "infrastructure_role" {
  name = "${var.project_name}-Infrastructure_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Infrastructure_Role"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

# Attach Terraform policy to Infrastructure Role
resource "aws_iam_role_policy" "infrastructure_policy" {
  name   = "${var.project_name}-TerraformPolicy"
  role   = aws_iam_role.infrastructure_role.id
  policy = file("${path.module}/policies/terraform-policy.json")
}

# Lambda Deployment Role (for Lambda code updates)
resource "aws_iam_role" "lambda_deployment_role" {
  name = "${var.project_name}-Lambda_Deployment_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Lambda_Deployment_Role"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

# Attach Lambda deployment policy
resource "aws_iam_role_policy" "lambda_deployment_policy" {
  name   = "${var.project_name}-LambdaDeploymentPolicy"
  role   = aws_iam_role.lambda_deployment_role.id
  policy = file("${path.module}/policies/lambda-deploy-policy.json")
}

# Lambda Execution Role (for Lambda runtime permissions)
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-Lambda_Execution_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "Lambda_Execution_Role"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

# Attach Lambda execution policy
resource "aws_iam_role_policy" "lambda_execution_policy" {
  name   = "${var.project_name}-LambdaExecutionPolicy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = file("${path.module}/policies/lambda-execution-policy.json")
}

# CloudWatch Log Groups for GitHub Actions
resource "aws_cloudwatch_log_group" "github_actions_infrastructure" {
  name              = "/aws/github-actions/infrastructure"
  retention_in_days = 7

  tags = {
    Name        = "github-actions-infrastructure-logs"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "github_actions_lambda" {
  name              = "/aws/github-actions/lambda"
  retention_in_days = 7

  tags = {
    Name        = "github-actions-lambda-logs"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
