# Infrastructure as Code - Terraform Configuration

This directory contains all Terraform configurations for the serverless monorepo project.

## 📁 Directory Structure

```
infrastructure/
├── backend-config.tf          # Shared S3 backend configuration
├── main.tf                    # Shared module calls (DRY principle)
├── variables.tf               # Shared variable definitions
├── outputs.tf                 # Shared outputs
├── modules/                   # Reusable Terraform modules
│   ├── api_gateway/
│   ├── dynamodb/
│   ├── iam/
│   ├── lambda/
│   └── s3/
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf           # Minimal - inherits from parent
│   │   └── terraform.tfvars  # Dev-specific values only
│   ├── staging/
│   │   ├── main.tf           # Minimal - inherits from parent
│   │   └── terraform.tfvars  # Staging-specific values only
│   └── prod/
│       ├── main.tf           # Minimal - inherits from parent
│       └── terraform.tfvars  # Prod-specific values only
├── global/                    # Global resources (OIDC, state backend)
├── tests/                     # Terraform tests
└── scripts/                   # Infrastructure validation scripts
```

## 🎯 DRY Principle Implementation

This structure follows the **Don't Repeat Yourself (DRY)** principle:

### Shared Configuration (No Duplication)
- **backend-config.tf** - S3 backend with DynamoDB locking (used by all environments)
- **main.tf** - Module calls (used by all environments)
- **variables.tf** - Variable definitions (used by all environments)
- **outputs.tf** - Output definitions (used by all environments)

### Environment-Specific Configuration (Minimal)
- **terraform.tfvars** - Only environment-specific values (dev, staging, prod)
- **main.tf** - Minimal placeholder (inherits shared configuration)

## 🚀 How to Deploy

### Initialize Terraform for an Environment

```bash
cd infrastructure/environments/dev

terraform init \
  -backend-config="bucket=terraform-state-123456789-us-east-1" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks" \
  -backend-config="encrypt=true"
```

### Plan Infrastructure Changes

```bash
terraform plan -var-file=terraform.tfvars
```

### Apply Infrastructure Changes

```bash
terraform apply -var-file=terraform.tfvars
```

### Destroy Infrastructure

```bash
terraform destroy -var-file=terraform.tfvars
```

## 📋 Environment Variables

Each environment has a `terraform.tfvars` file with environment-specific values:

### Development (dev)
- Lambda Memory: 256 MB
- Lambda Timeout: 30 seconds
- Log Retention: 7 days
- API Throttle: 5000 burst, 2000 rate

### Staging
- Lambda Memory: 512 MB
- Lambda Timeout: 60 seconds
- Log Retention: 14 days
- API Throttle: 10000 burst, 5000 rate

### Production (prod)
- Lambda Memory: 1024 MB
- Lambda Timeout: 60 seconds
- Log Retention: 30 days
- API Throttle: 20000 burst, 10000 rate

## 🔐 Backend Configuration

All environments use the same S3 backend with DynamoDB locking:

- **S3 Bucket**: `terraform-state-{account-id}-{region}`
- **DynamoDB Table**: `terraform-locks`
- **Encryption**: Enabled (KMS)
- **Versioning**: Enabled
- **State Key**: `{environment}/terraform.tfstate`

## 📦 Modules

Each module is self-contained and reusable:

### S3 Module
- Terraform state bucket
- Lambda code storage bucket
- Encryption and versioning

### IAM Module
- Infrastructure role (for Terraform)
- Lambda deployment role (for CI/CD)
- Lambda execution role (for runtime)
- GitHub OIDC provider configuration

### DynamoDB Module
- Items table with GSI
- On-demand billing
- Point-in-time recovery
- TTL support

### Lambda Module
- CRUD handler function
- CloudWatch logs
- Environment variables
- Execution role attachment

### API Gateway Module
- REST API with CRUD endpoints
- Lambda integration
- CORS configuration
- Request/response models
- CloudWatch logging

## 🧪 Validation

### Validate Terraform Syntax

```bash
terraform validate
```

### Format Terraform Code

```bash
terraform fmt -recursive
```

### Run Infrastructure Validation Scripts

```bash
npm run validate:infrastructure
npm run detect:orphans
npm run analyze:costs
```

## 📝 Best Practices

1. **Always use terraform.tfvars** - Never hardcode values in main.tf
2. **Use modules** - Keep resource definitions in modules, not environments
3. **Validate before applying** - Always run `terraform plan` first
4. **Use state locking** - Prevents concurrent modifications
5. **Enable encryption** - All state files are encrypted
6. **Tag resources** - All resources are tagged with environment and project

## 🔗 Related Documentation

- [AWS Documentation](../ARCHITECTURE.md)
- [Configuration Guide](../CONFIGURATION.md)
- [OIDC Setup](../OIDC_SETUP.md)
- [Deployment Guide](../DEPLOYMENT.md)

## 🆘 Troubleshooting

### State Lock Issues

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Backend Configuration Errors

Ensure all `-backend-config` flags are provided during `terraform init`.

### Module Not Found

Verify module paths in `main.tf` are correct relative to the environment directory.

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the spec documents in `.kiro/specs/serverless-monorepo-aws/`
3. Check AWS CloudTrail for API errors
