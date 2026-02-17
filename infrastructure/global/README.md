# Global Infrastructure - Terraform State Backend

This directory contains one-time global resources shared by all environments.

## 📋 Resources Created

| Resource | Purpose |
|----------|---------|
| S3 Bucket | Terraform state storage (encrypted, versioned) |
| S3 Logs Bucket | Access logs for state bucket |
| DynamoDB Table | State locking (prevents concurrent modifications) |
| CloudWatch Logs | Terraform operation logs |
| IAM OIDC Provider | GitHub Actions authentication |

## 🚀 Deployment

### Step 1: Initialize
```bash
terraform -chdir=infrastructure/global init
```

### Step 2: Plan & Apply
```bash
terraform -chdir=infrastructure/global plan
terraform -chdir=infrastructure/global apply
```

### Step 3: Get Outputs
```bash
terraform -chdir=infrastructure/global output
```

## 📝 Using Global Resources

After deployment, other environments use the S3 backend:

```bash
terraform -chdir=infrastructure/environments/dev init \
  -backend-config="bucket=terraform-state-{account-id}-{region}" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region={region}" \
  -backend-config="dynamodb_table=terraform-locks" \
  -backend-config="encrypt=true"
```

## 🔐 Security

✅ Encryption at rest (AES256)  
✅ Versioning enabled  
✅ Access logging enabled  
✅ Public access blocked  
✅ State locking via DynamoDB  
✅ GitHub OIDC for CI/CD  

## 📚 See Also

- [README.md](../README.md) - Project overview
- [bootstrap/README.md](./bootstrap/README.md) - OIDC setup details
- [CONFIGURATION.md](../../CONFIGURATION.md) - Backend configuration

