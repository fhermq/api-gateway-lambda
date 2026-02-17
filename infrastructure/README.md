# Infrastructure as Code - Terraform

This directory contains all Terraform configurations for the serverless monorepo.

## 📁 Structure

```
infrastructure/
├── modules/                   # Reusable Terraform modules
│   ├── api_gateway/          # REST API with Lambda integration
│   ├── dynamodb/             # DynamoDB table with GSI
│   ├── iam/                  # IAM roles and policies
│   ├── lambda/               # Lambda function with CloudWatch
│   └── s3/                   # S3 buckets for state & code
├── environments/             # Environment-specific configs
│   ├── dev/                  # Development environment
│   ├── staging/              # Staging environment
│   └── prod/                 # Production environment
├── global/                   # Global resources (OIDC, state backend)
├── bootstrap/                # One-time OIDC setup
├── scripts/                  # Validation & cost analysis scripts
└── tests/                    # Terraform tests
```

## 🚀 Quick Start

### Initialize Terraform
```bash
terraform -chdir=infrastructure/environments/dev init
```

### Validate Configuration
```bash
terraform -chdir=infrastructure/environments/dev validate
npm run validate:infrastructure
```

### Plan & Apply
```bash
terraform -chdir=infrastructure/environments/dev plan
terraform -chdir=infrastructure/environments/dev apply
```

## 📋 Environments

Each environment has its own configuration:

| Environment | Lambda Memory | Timeout | Log Retention | Throttle |
|-------------|---------------|---------|---------------|----------|
| dev | 256 MB | 30s | 7 days | 5000/2000 |
| staging | 512 MB | 30s | 30 days | 10000/5000 |
| prod | 512 MB | 60s | 30 days | 10000/5000 |

## 🔐 Backend

All environments use S3 + DynamoDB for state management:
- **Encryption**: KMS enabled
- **Versioning**: Enabled
- **Locking**: DynamoDB table
- **Access Logging**: Enabled

## 📦 Modules

| Module | Purpose |
|--------|---------|
| `api_gateway` | REST API with CRUD endpoints |
| `dynamodb` | Items table with GSI |
| `iam` | Roles for Terraform, Lambda, GitHub OIDC |
| `lambda` | CRUD handler function |
| `s3` | State bucket, code bucket, logs |

## 🧪 Validation

```bash
# Validate syntax
terraform -chdir=infrastructure/environments/dev validate

# Check for orphaned resources
npm run detect:orphans

# Analyze costs
npm run analyze:costs
```

## 📚 Documentation

- [README.md](../README.md) - Project overview
- [CONFIGURATION.md](../CONFIGURATION.md) - Setup & variables
- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [scripts/README.md](./scripts/README.md) - Validation scripts
- [bootstrap/README.md](./bootstrap/README.md) - OIDC setup
