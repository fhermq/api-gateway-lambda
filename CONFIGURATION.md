# Configuration Guide

This document describes all environment variables, Terraform variables, and GitHub Actions secrets required to configure the serverless monorepo application.

## Table of Contents

1. [Terraform Variables](#terraform-variables)
2. [Lambda Environment Variables](#lambda-environment-variables)
3. [GitHub Actions Secrets](#github-actions-secrets)
4. [Environment-Specific Configurations](#environment-specific-configurations)
5. [Local Development Setup](#local-development-setup)

## Terraform Variables

### Global Variables

**File**: `infrastructure/global/terraform.tfvars`

```hcl
aws_region = "us-east-1"
project_name = "api-gateway-lambda"
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for all resources |
| `project_name` | string | `api-gateway-lambda` | Project name for resource naming |

### Bootstrap Variables

**File**: `infrastructure/bootstrap/terraform.tfvars`

```hcl
aws_region = "us-east-1"
project_name = "api-gateway-lambda"
github_org = "YOUR_ORG"
github_repo = "YOUR_REPO"
github_branch = "main"
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for bootstrap resources |
| `project_name` | string | `api-gateway-lambda` | Project name for resource naming |
| `github_org` | string | Required | GitHub organization name |
| `github_repo` | string | Required | GitHub repository name |
| `github_branch` | string | `main` | GitHub branch for OIDC trust policy |

### Environment-Specific Variables

**Dev Environment**: `infrastructure/environments/dev/terraform.tfvars`

```hcl
aws_region = "us-east-1"
environment = "dev"
project_name = "api-gateway-lambda"

# Lambda Configuration
lambda_memory = 256
lambda_timeout = 30
lambda_reserved_concurrent_executions = -1  # Unlimited

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_point_in_time_recovery_enabled = true

# API Gateway Configuration
api_gateway_throttle_settings = {
  rate_limit  = 10000
  burst_limit = 5000
}

# Tags
tags = {
  Environment = "dev"
  Project     = "api-gateway-lambda"
  ManagedBy   = "Terraform"
}
```

**Staging Environment**: `infrastructure/environments/staging/terraform.tfvars`

```hcl
aws_region = "us-east-1"
environment = "staging"
project_name = "api-gateway-lambda"

# Lambda Configuration
lambda_memory = 512
lambda_timeout = 30
lambda_reserved_concurrent_executions = 100

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_point_in_time_recovery_enabled = true

# API Gateway Configuration
api_gateway_throttle_settings = {
  rate_limit  = 10000
  burst_limit = 5000
}

# Tags
tags = {
  Environment = "staging"
  Project     = "api-gateway-lambda"
  ManagedBy   = "Terraform"
}
```

**Production Environment**: `infrastructure/environments/prod/terraform.tfvars`

```hcl
aws_region = "us-east-1"
environment = "prod"
project_name = "api-gateway-lambda"

# Lambda Configuration
lambda_memory = 1024
lambda_timeout = 30
lambda_reserved_concurrent_executions = 500

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_point_in_time_recovery_enabled = true

# API Gateway Configuration
api_gateway_throttle_settings = {
  rate_limit  = 10000
  burst_limit = 5000
}

# Tags
tags = {
  Environment = "prod"
  Project     = "api-gateway-lambda"
  ManagedBy   = "Terraform"
  CostCenter  = "engineering"
}
```

### Common Terraform Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for resources |
| `environment` | string | Required | Environment name (dev, staging, prod) |
| `project_name` | string | `api-gateway-lambda` | Project name for resource naming |
| `lambda_memory` | number | 256 | Lambda function memory in MB |
| `lambda_timeout` | number | 30 | Lambda function timeout in seconds |
| `lambda_reserved_concurrent_executions` | number | -1 | Reserved concurrency (-1 = unlimited) |
| `dynamodb_billing_mode` | string | `PAY_PER_REQUEST` | DynamoDB billing mode |
| `dynamodb_point_in_time_recovery_enabled` | bool | true | Enable DynamoDB PITR |
| `api_gateway_throttle_settings` | object | See above | API Gateway throttling settings |
| `tags` | map(string) | See above | Resource tags |

## Lambda Environment Variables

### Lambda Function Environment Variables

Set via Terraform in `infrastructure/modules/lambda/main.tf`:

```hcl
environment {
  variables = {
    ENVIRONMENT              = var.environment
    DYNAMODB_TABLE_NAME      = aws_dynamodb_table.items.name
    LOG_LEVEL                = var.log_level
    CORS_ALLOWED_ORIGINS     = var.cors_allowed_origins
    REQUEST_TIMEOUT_MS       = var.request_timeout_ms
  }
}
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENVIRONMENT` | string | dev/staging/prod | Current environment |
| `DYNAMODB_TABLE_NAME` | string | items-{env} | DynamoDB table name |
| `LOG_LEVEL` | string | INFO | Logging level (DEBUG, INFO, WARN, ERROR) |
| `CORS_ALLOWED_ORIGINS` | string | * | CORS allowed origins (comma-separated) |
| `REQUEST_TIMEOUT_MS` | number | 30000 | Request timeout in milliseconds |

### Example Lambda Environment Configuration

**Development**:
```bash
ENVIRONMENT=dev
DYNAMODB_TABLE_NAME=items-dev
LOG_LEVEL=DEBUG
CORS_ALLOWED_ORIGINS=*
REQUEST_TIMEOUT_MS=30000
```

**Production**:
```bash
ENVIRONMENT=prod
DYNAMODB_TABLE_NAME=items-prod
LOG_LEVEL=INFO
CORS_ALLOWED_ORIGINS=https://api.example.com,https://app.example.com
REQUEST_TIMEOUT_MS=30000
```

## GitHub Actions Secrets

### Required Secrets

Set these secrets in your GitHub repository settings:

**Settings → Secrets and variables → Actions**

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ACCOUNT_ID` | AWS Account ID | `123456789012` |
| `AWS_REGION` | AWS Region | `us-east-1` |
| `TERRAFORM_VERSION` | Terraform version | `1.6.0` |

### Optional Secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | `https://hooks.slack.com/...` |
| `DATADOG_API_KEY` | Datadog API key for monitoring | `abc123def456` |
| `SENTRY_DSN` | Sentry DSN for error tracking | `https://key@sentry.io/project` |

### Setting Secrets in GitHub

1. Go to repository Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Enter secret name and value
5. Click "Add secret"

**Example**:
```bash
# Set AWS_ACCOUNT_ID
Name: AWS_ACCOUNT_ID
Value: 123456789012

# Set AWS_REGION
Name: AWS_REGION
Value: us-east-1

# Set TERRAFORM_VERSION
Name: TERRAFORM_VERSION
Value: 1.6.0
```

## Environment-Specific Configurations

### Development Environment

**Purpose**: Local development and testing

**Configuration**:
```hcl
environment = "dev"
lambda_memory = 256
lambda_timeout = 30
lambda_reserved_concurrent_executions = -1
dynamodb_billing_mode = "PAY_PER_REQUEST"
```

**Deployment**:
- Automatic on push to main branch
- No approval gates
- Shorter log retention (7 days)

**Access**:
- All team members can deploy
- No restrictions on infrastructure changes

### Staging Environment

**Purpose**: Pre-production testing and validation

**Configuration**:
```hcl
environment = "staging"
lambda_memory = 512
lambda_timeout = 30
lambda_reserved_concurrent_executions = 100
dynamodb_billing_mode = "PAY_PER_REQUEST"
```

**Deployment**:
- Automatic on push to main branch
- Manual approval for infrastructure changes
- Standard log retention (30 days)

**Access**:
- Team leads can approve deployments
- Infrastructure changes require review

### Production Environment

**Purpose**: Live production workloads

**Configuration**:
```hcl
environment = "prod"
lambda_memory = 1024
lambda_timeout = 30
lambda_reserved_concurrent_executions = 500
dynamodb_billing_mode = "PAY_PER_REQUEST"
```

**Deployment**:
- Manual approval required for all changes
- Approval gates in GitHub Actions
- Extended log retention (90 days)

**Access**:
- Only authorized team members can approve
- All changes require code review
- Deployment history tracked

## Local Development Setup

### Prerequisites

- Node.js 18+
- Terraform 1.6+
- AWS CLI v2
- Git

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_ORG/api-gateway-lambda.git
cd api-gateway-lambda
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (us-east-1)
# Enter your default output format (json)
```

Or use environment variables:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=us-east-1
```

### Step 4: Initialize Terraform

```bash
cd infrastructure/environments/dev
terraform init
```

### Step 5: Create Local Environment File

Create `.env.local` in project root:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# Environment
ENVIRONMENT=dev

# DynamoDB
DYNAMODB_TABLE_NAME=items-dev

# Lambda
LOG_LEVEL=DEBUG
CORS_ALLOWED_ORIGINS=*

# API Gateway
API_GATEWAY_URL=https://api-id.execute-api.us-east-1.amazonaws.com/dev
```

### Step 6: Load Environment Variables

```bash
# For bash/zsh
source .env.local

# For fish
set -a; source .env.local; set -a
```

### Step 7: Validate Setup

```bash
# Validate Terraform
npm run validate:terraform

# Validate infrastructure
npm run validate:infrastructure

# Run tests
npm test
```

## Configuration Best Practices

### 1. Environment Parity

Keep configurations consistent across environments:
- Same Lambda timeout
- Same DynamoDB schema
- Same API Gateway endpoints

Differences should be minimal:
- Lambda memory (higher in prod)
- Reserved concurrency (higher in prod)
- Log retention (longer in prod)

### 2. Secrets Management

**Do**:
- Store secrets in GitHub Actions Secrets
- Use IAM roles for AWS authentication
- Rotate secrets regularly
- Use environment-specific secrets

**Don't**:
- Hardcode secrets in code
- Store secrets in .env files in git
- Share secrets via email or chat
- Use the same secrets across environments

### 3. Variable Naming

Use consistent naming conventions:
- Prefix with environment: `dev_`, `staging_`, `prod_`
- Use uppercase for constants: `DYNAMODB_TABLE_NAME`
- Use lowercase for variables: `lambda_memory`
- Use descriptive names: `lambda_reserved_concurrent_executions`

### 4. Documentation

Document all configuration changes:
- Why the change was made
- What values were changed
- When the change was made
- Who made the change

### 5. Validation

Always validate configuration:
```bash
# Validate Terraform
terraform validate

# Validate formatting
terraform fmt -check

# Plan changes
terraform plan
```

## Troubleshooting

### AWS Credentials Not Found

**Error**: `AWS credentials not configured or invalid`

**Solution**:
```bash
aws configure
# or
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
```

### Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# List locks
terraform state list

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Lambda Environment Variables Not Set

**Error**: `DYNAMODB_TABLE_NAME is undefined`

**Solution**:
1. Check Terraform variables are set correctly
2. Verify Lambda environment variables in Terraform
3. Redeploy Lambda function

### GitHub Actions Secrets Not Available

**Error**: `Secrets are not available in this context`

**Solution**:
1. Verify secrets are set in repository settings
2. Check workflow has `permissions: id-token: write`
3. Verify secret names match exactly (case-sensitive)

## Related Documentation

- [README.md](./README.md) - Project overview
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Production deployment
- [infrastructure/bootstrap/README.md](./infrastructure/bootstrap/README.md) - OIDC setup
- [infrastructure/scripts/README.md](./infrastructure/scripts/README.md) - Infrastructure scripts
