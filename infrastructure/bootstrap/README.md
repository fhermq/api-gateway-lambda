# Bootstrap Terraform Module

This module sets up the one-time prerequisites for GitHub Actions to deploy infrastructure and Lambda code. It creates:

- GitHub OIDC provider for secure authentication
- IAM roles with least-privilege permissions
- CloudWatch log groups for workflow logs

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- GitHub repository information (organization, repo name)

## Quick Start

### Step 1: Navigate to Bootstrap Directory

```bash
cd infrastructure/bootstrap
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Apply Bootstrap Configuration

Replace `YOUR_ORG`, `YOUR_REPO`, and `api-gateway-lambda` with your actual values:

```bash
terraform apply \
  -var="project_name=api-gateway-lambda" \
  -var="github_org=YOUR_ORG" \
  -var="github_repo=YOUR_REPO"
```

Optional: Specify a different branch (default is `main`):

```bash
terraform apply \
  -var="project_name=api-gateway-lambda" \
  -var="github_org=YOUR_ORG" \
  -var="github_repo=YOUR_REPO" \
  -var="github_branch=develop"
```

### Step 4: Verify Setup

After `terraform apply` completes, you'll see outputs showing:

```
infrastructure_role_arn = "arn:aws:iam::123456789012:role/api-gateway-lambda-Infrastructure_Role"
lambda_deployment_role_arn = "arn:aws:iam::123456789012:role/api-gateway-lambda-Lambda_Deployment_Role"
lambda_execution_role_arn = "arn:aws:iam::123456789012:role/api-gateway-lambda-Lambda_Execution_Role"
oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

Verify in AWS Console:
1. Go to IAM → Roles
2. Check that `api-gateway-lambda-Infrastructure_Role`, `api-gateway-lambda-Lambda_Deployment_Role`, and `api-gateway-lambda-Lambda_Execution_Role` exist
3. Go to IAM → Identity providers
4. Check that GitHub OIDC provider exists

## What Gets Created

### GitHub OIDC Provider
- Enables GitHub Actions to authenticate to AWS without long-lived credentials
- Restricted to your specific repository and branch
- Automatically rotates tokens

### Infrastructure_Role
- **Purpose**: Allows GitHub Actions to deploy infrastructure via Terraform
- **Name**: `api-gateway-lambda-Infrastructure_Role`
- **Permissions**: S3, DynamoDB, API Gateway, Lambda, IAM, CloudWatch, KMS
- **Trust**: Only from your GitHub repository on specified branch
- **Policy**: `policies/terraform-policy.json`

### Lambda_Deployment_Role
- **Purpose**: Allows GitHub Actions to update Lambda code
- **Name**: `api-gateway-lambda-Lambda_Deployment_Role`
- **Permissions**: S3 (get/put), Lambda (update code), CloudWatch Logs
- **Trust**: Only from your GitHub repository on specified branch
- **Policy**: `policies/lambda-deploy-policy.json`

### Lambda_Execution_Role
- **Purpose**: Allows Lambda functions to access DynamoDB and CloudWatch
- **Name**: `api-gateway-lambda-Lambda_Execution_Role`
- **Permissions**: DynamoDB (CRUD), CloudWatch Logs
- **Trust**: Lambda service only
- **Policy**: `policies/lambda-execution-policy.json`

### CloudWatch Log Groups
- `/aws/github-actions/infrastructure` - Infrastructure deployment logs (7-day retention)
- `/aws/github-actions/lambda` - Lambda deployment logs (7-day retention)

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for bootstrap resources |
| `project_name` | string | Required | Project name for resource naming (e.g., api-gateway-lambda) |
| `github_org` | string | Required | GitHub organization name |
| `github_repo` | string | Required | GitHub repository name |
| `github_branch` | string | `main` | GitHub branch for OIDC trust policy |

## Outputs

| Output | Description |
|--------|-------------|
| `oidc_provider_arn` | ARN of GitHub OIDC provider |
| `infrastructure_role_arn` | ARN of Infrastructure_Role |
| `infrastructure_role_name` | Name of Infrastructure_Role |
| `lambda_deployment_role_arn` | ARN of Lambda_Deployment_Role |
| `lambda_deployment_role_name` | Name of Lambda_Deployment_Role |
| `lambda_execution_role_arn` | ARN of Lambda_Execution_Role |
| `lambda_execution_role_name` | Name of Lambda_Execution_Role |
| `github_actions_infrastructure_log_group` | CloudWatch log group for infrastructure |
| `github_actions_lambda_log_group` | CloudWatch log group for Lambda |

## Cleanup

To remove all bootstrap resources:

```bash
terraform destroy \
  -var="project_name=api-gateway-lambda" \
  -var="github_org=YOUR_ORG" \
  -var="github_repo=YOUR_REPO"
```

**Warning**: This will delete the OIDC provider and IAM roles. GitHub Actions workflows will fail until bootstrap is re-applied.

## Troubleshooting

### Error: "github_org is required"

**Solution**: Provide all required variables:
```bash
terraform apply \
  -var="project_name=api-gateway-lambda" \
  -var="github_org=YOUR_ORG" \
  -var="github_repo=YOUR_REPO"
```

### Error: "Access Denied" when running terraform apply

**Solution**: Ensure your AWS credentials have IAM permissions to create roles and OIDC providers.

### Roles not appearing in AWS Console

**Solution**: 
1. Verify `terraform apply` completed successfully
2. Check AWS region (default is us-east-1)
3. Run `terraform output` to see created resources

### GitHub Actions still can't assume role

**Solution**:
1. Verify GitHub Secret `AWS_ACCOUNT_ID` is set in repository
2. Verify repository name matches exactly (case-sensitive)
3. Verify branch name matches (default is `main`)
4. Check CloudWatch logs: `/aws/github-actions/infrastructure`

## Next Steps

After bootstrap is complete:

1. Commit bootstrap code to repository
2. Push to GitHub
3. GitHub Actions workflows can now assume roles and deploy infrastructure
4. Proceed with Task 26: Infrastructure Provisioning Workflow

## Security Notes

- OIDC tokens are short-lived (1 hour) and automatically rotated
- No long-lived AWS credentials are stored in GitHub
- Roles are restricted to specific repository and branch
- All permissions follow least-privilege principle
- CloudWatch logs capture all deployments for audit trail

---

**Last Updated**: February 17, 2026
**Status**: Bootstrap module ready for deployment
