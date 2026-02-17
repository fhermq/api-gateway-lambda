# IAM Roles for Infrastructure and Lambda Deployment
# Implements least privilege principle with specific permissions for each role

# Data source for GitHub OIDC provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# ============================================================================
# Infrastructure Role - For Terraform Infrastructure Provisioning
# ============================================================================

resource "aws_iam_role" "infrastructure_role" {
  name               = "Infrastructure_Role"
  assume_role_policy = data.aws_iam_policy_document.infrastructure_trust.json

  tags = {
    Name      = "Infrastructure_Role"
    Purpose   = "Terraform Infrastructure Provisioning"
    ManagedBy = "Terraform"
  }
}

# Trust policy for Infrastructure Role - allows GitHub OIDC to assume this role
data "aws_iam_policy_document" "infrastructure_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

# Policy for Infrastructure Role - permissions for Terraform to manage infrastructure
data "aws_iam_policy_document" "infrastructure_policy" {
  # S3 permissions for state bucket
  statement {
    sid    = "S3StateManagement"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation"
    ]
    resources = [var.terraform_state_bucket_arn]
  }

  statement {
    sid    = "S3StateFileAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.terraform_state_bucket_arn}/*"]
  }

  # DynamoDB permissions for state locking
  statement {
    sid    = "DynamoDBStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [var.terraform_locks_table_arn]
  }

  # API Gateway permissions
  statement {
    sid    = "APIGatewayManagement"
    effect = "Allow"
    actions = [
      "apigateway:*"
    ]
    resources = ["arn:aws:apigateway:${var.aws_region}::/*"]
  }

  # Lambda permissions
  statement {
    sid    = "LambdaManagement"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:ListVersionsByFunction",
      "lambda:PublishVersion",
      "lambda:CreateAlias",
      "lambda:UpdateAlias",
      "lambda:DeleteAlias"
    ]
    resources = ["arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:*"]
  }

  # DynamoDB table management
  statement {
    sid    = "DynamoDBTableManagement"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*"]
  }

  # DynamoDB GSI management
  statement {
    sid    = "DynamoDBGSIManagement"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateTable"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*/index/*"]
  }

  # IAM role and policy management
  statement {
    sid    = "IAMRoleManagement"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Lambda_Execution_Role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Lambda_Deployment_Role"
    ]
  }

  statement {
    sid    = "IAMPolicyManagement"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Lambda_Execution_Policy",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Lambda_Deployment_Policy"
    ]
  }

  statement {
    sid    = "IAMAttachPolicy"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Lambda_Execution_Role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Lambda_Deployment_Role"
    ]
  }

  # S3 bucket management for Lambda code
  statement {
    sid    = "S3LambdaCodeBucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketEncryption",
      "s3:PutBucketEncryption",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::lambda-code-*"]
  }

  statement {
    sid    = "S3LambdaCodeObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::lambda-code-*/*"]
  }

  # CloudWatch Logs permissions
  statement {
    sid    = "CloudWatchLogsManagement"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
  }

  # KMS permissions for encryption
  statement {
    sid    = "KMSEncryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${var.aws_region}.amazonaws.com",
        "dynamodb.${var.aws_region}.amazonaws.com"
      ]
    }
  }

  # CloudFormation permissions (if needed for stack management)
  statement {
    sid    = "CloudFormationManagement"
    effect = "Allow"
    actions = [
      "cloudformation:DescribeStacks",
      "cloudformation:ListStacks"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "infrastructure_policy" {
  name   = "Infrastructure_Policy"
  role   = aws_iam_role.infrastructure_role.id
  policy = data.aws_iam_policy_document.infrastructure_policy.json
}

# ============================================================================
# Lambda Execution Role - For Lambda Function Runtime
# ============================================================================

resource "aws_iam_role" "lambda_execution_role" {
  name               = "Lambda_Execution_Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_trust.json

  tags = {
    Name      = "Lambda_Execution_Role"
    Purpose   = "Lambda Function Runtime"
    ManagedBy = "Terraform"
  }
}

# Trust policy for Lambda Execution Role - allows Lambda service to assume this role
data "aws_iam_policy_document" "lambda_execution_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Policy for Lambda Execution Role - permissions for Lambda to access DynamoDB and CloudWatch
data "aws_iam_policy_document" "lambda_execution_policy" {
  # DynamoDB permissions for CRUD operations
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*"
    ]
  }

  # CloudWatch Logs permissions
  statement {
    sid    = "CloudWatchLogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
  }

  # X-Ray write access for tracing (optional but recommended)
  statement {
    sid    = "XRayWrite"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name   = "Lambda_Execution_Policy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

# ============================================================================
# Lambda Deployment Role - For GitHub Actions to Update Lambda Code
# ============================================================================

resource "aws_iam_role" "lambda_deployment_role" {
  name               = "Lambda_Deployment_Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_deployment_trust.json

  tags = {
    Name      = "Lambda_Deployment_Role"
    Purpose   = "Lambda Code Deployment from GitHub Actions"
    ManagedBy = "Terraform"
  }
}

# Trust policy for Lambda Deployment Role - allows GitHub OIDC to assume this role
data "aws_iam_policy_document" "lambda_deployment_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

# Policy for Lambda Deployment Role - permissions to update Lambda code
data "aws_iam_policy_document" "lambda_deployment_policy" {
  # S3 permissions to upload Lambda code
  statement {
    sid    = "S3LambdaCodeUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::lambda-code-*/*"]
  }

  # Lambda update permissions
  statement {
    sid    = "LambdaCodeUpdate"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction"
    ]
    resources = ["arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:api-handler"]
  }

  # CloudWatch Logs for deployment logs
  statement {
    sid    = "CloudWatchLogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/deployment*"]
  }
}

resource "aws_iam_role_policy" "lambda_deployment_policy" {
  name   = "Lambda_Deployment_Policy"
  role   = aws_iam_role.lambda_deployment_role.id
  policy = data.aws_iam_policy_document.lambda_deployment_policy.json
}
