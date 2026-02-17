# Global Infrastructure - Terraform State Backend

This directory contains the global infrastructure resources that are created ONCE and shared by all environments.

## 📋 Resources Created

### S3 Buckets
1. **terraform-state-{account-id}-{region}**
   - Stores Terraform state files for all environments
   - Versioning enabled for state history
   - Server-side encryption enabled (AES256)
   - Public access blocked
   - Access logging enabled

2. **terraform-state-logs-{account-id}-{region}**
   - Stores access logs for the state bucket
   - Versioning enabled
   - Public access blocked

### DynamoDB Table
- **terraform-locks**
  - Prevents concurrent Terraform modifications
  - On-demand billing
  - Point-in-time recovery enabled
  - Server-side encryption enabled

### CloudWatch Log Group
- **/aws/terraform/operations**
  - Logs all Terraform operations
  - 30-day retention

## 🚀 Deployment Instructions

### Step 1: Initialize Terraform (Local State)

```bash
cd infrastructure/global
terraform init
```

This will initialize Terraform with local state (stored in `terraform.tfstate`).

### Step 2: Plan the Deployment

```bash
terraform plan -var-file=terraform.tfvars
```

Review the resources that will be created.

### Step 3: Apply the Configuration

```bash
terraform apply -var-file=terraform.tfvars
```

This creates:
- S3 bucket for state
- S3 bucket for logs
- DynamoDB table for locking
- CloudWatch log group

### Step 4: Migrate to S3 Backend (Optional but Recommended)

After the S3 bucket and DynamoDB table are created, you can migrate the local state to S3:

```bash
# Get the bucket name from outputs
BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name)
REGION=$(terraform output -raw aws_region)

# Create a backend configuration file
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "global/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
EOF

# Reinitialize Terraform to migrate state
terraform init
```

When prompted, type `yes` to confirm the migration.

## 📊 Outputs

After deployment, you can retrieve important information:

```bash
# Get the state bucket name
terraform output terraform_state_bucket_name

# Get the locks table name
terraform output terraform_locks_table_name

# Get the backend configuration command for other environments
terraform output backend_config_command

# Get AWS account ID
terraform output aws_account_id
```

## 🔐 Security Features

✅ **Encryption** - All data encrypted at rest (AES256)  
✅ **Versioning** - State history preserved for recovery  
✅ **Access Logging** - All access to state bucket logged  
✅ **Public Access Blocked** - No public access possible  
✅ **State Locking** - Prevents concurrent modifications  
✅ **Point-in-Time Recovery** - DynamoDB PITR enabled  

## 📝 Usage in Other Environments

Once the global resources are created, use them in other environments:

```bash
cd infrastructure/environments/dev

# Initialize with S3 backend
terraform init \
  -backend-config="bucket=terraform-state-{account-id}-{region}" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region={region}" \
  -backend-config="dynamodb_table=terraform-locks" \
  -backend-config="encrypt=true"
```

## 🔄 Updating Global Resources

To update global resources:

```bash
cd infrastructure/global

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

**Important**: Changes to global resources affect all environments. Always review plans carefully.

## 🗑️ Destroying Global Resources

To destroy global resources (use with caution):

```bash
cd infrastructure/global

# Ensure no other environments are using the state backend
# Backup the state file first
cp terraform.tfstate terraform.tfstate.backup

# Destroy resources
terraform destroy -var-file=terraform.tfvars
```

**Warning**: Destroying these resources will:
- Delete all Terraform state files
- Delete all access logs
- Delete the state locking table

Only do this if you're completely decommissioning the project.

## 🆘 Troubleshooting

### S3 Bucket Already Exists

If you get an error that the bucket already exists, it means:
1. The bucket was created in a previous run
2. Another project is using the same bucket name

Solution: Use a different AWS region or account.

### DynamoDB Table Already Exists

Similar to S3, if the table already exists, it was created previously.

Solution: Either reuse the existing table or use a different region/account.

### State Lock Timeout

If you get a state lock timeout:

```bash
# List locks
terraform force-unlock <LOCK_ID>
```

## 📞 Support

For issues:
1. Check AWS CloudTrail for API errors
2. Verify IAM permissions
3. Check S3 bucket and DynamoDB table exist
4. Review CloudWatch logs in `/aws/terraform/operations`


## 🔐 GitHub OIDC Provider Configuration

The global infrastructure also creates an AWS IAM OIDC provider for GitHub Actions. This enables GitHub Actions workflows to assume AWS roles without storing long-lived AWS credentials.

### What Gets Created

- **AWS IAM OIDC Provider** for GitHub
  - URL: `https://token.actions.githubusercontent.com`
  - Automatically fetches GitHub's OIDC thumbprint
  - Enables GitHub Actions to authenticate to AWS

### How It Works

1. GitHub Actions generates a JWT token signed by GitHub
2. GitHub Actions sends this token to AWS
3. AWS verifies the token using the OIDC provider
4. AWS issues temporary credentials to the GitHub Actions workflow
5. The workflow uses these credentials to deploy infrastructure or code

### Using OIDC in GitHub Actions

After the OIDC provider is created, you can use it in GitHub Actions workflows:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Assume AWS Role
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::{account-id}:role/Infrastructure_Role
          aws-region: {region}
      
      - name: Deploy Infrastructure
        run: |
          cd infrastructure/environments/dev
          terraform init
          terraform apply -auto-approve
```

### Outputs

After deployment, retrieve the OIDC provider information:

```bash
# Get the OIDC provider ARN
terraform output github_oidc_provider_arn

# Get the OIDC provider URL
terraform output github_oidc_provider_url
```

### Security Considerations

✅ **No Long-Lived Credentials** - Uses temporary credentials only  
✅ **Repository Scoped** - Can restrict to specific repositories  
✅ **Branch Scoped** - Can restrict to specific branches  
✅ **Audit Trail** - All actions logged in CloudTrail  
✅ **Automatic Token Rotation** - GitHub rotates tokens regularly  

### Next Steps

1. Deploy the global infrastructure (this creates the OIDC provider)
2. Create IAM roles with trust relationships to the OIDC provider (Task 5)
3. Configure GitHub Actions workflows to use the roles (Tasks 25-26)

