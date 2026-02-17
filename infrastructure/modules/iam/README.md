# IAM Module - Roles and Policies

This module creates three IAM roles with least privilege permissions for the serverless monorepo project.

## 📋 Roles Created

### 1. Infrastructure_Role
**Purpose**: Terraform infrastructure provisioning via GitHub Actions

**Permissions**:
- S3: Manage Terraform state bucket and files
- DynamoDB: State locking operations
- API Gateway: Full management
- Lambda: Create, update, delete functions
- DynamoDB: Table and GSI management
- IAM: Create and manage Lambda roles
- CloudWatch Logs: Create and manage log groups
- KMS: Encryption key operations

**Trust Relationship**: GitHub OIDC provider (specific repository and branch)

### 2. Lambda_Execution_Role
**Purpose**: Runtime permissions for Lambda functions

**Permissions**:
- DynamoDB: CRUD operations on items table and GSI
- CloudWatch Logs: Write logs
- X-Ray: Tracing (optional)

**Trust Relationship**: Lambda service

### 3. Lambda_Deployment_Role
**Purpose**: GitHub Actions Lambda code deployment

**Permissions**:
- S3: Upload Lambda code to deployment bucket
- Lambda: Update function code and configuration
- CloudWatch Logs: Write deployment logs

**Trust Relationship**: GitHub OIDC provider (specific repository and branch)

## 🔐 Security Features

✅ **Least Privilege** - Each role has only required permissions  
✅ **Repository Scoped** - GitHub roles restricted to specific repository  
✅ **Branch Scoped** - GitHub roles restricted to specific branch  
✅ **Resource Scoped** - Permissions limited to specific resources  
✅ **No Wildcards** - Specific resource ARNs used where possible  
✅ **Audit Trail** - All actions logged in CloudTrail  

## 📝 Variables

| Variable | Type | Description | Required |
|----------|------|-------------|----------|
| `aws_region` | string | AWS region | Yes |
| `terraform_state_bucket_arn` | string | ARN of Terraform state bucket | Yes |
| `terraform_locks_table_arn` | string | ARN of Terraform locks table | Yes |
| `github_repository` | string | GitHub repo in format `owner/repo` | Yes |
| `github_branch` | string | GitHub branch (default: main) | No |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `infrastructure_role_arn` | ARN of Infrastructure Role |
| `infrastructure_role_name` | Name of Infrastructure Role |
| `lambda_execution_role_arn` | ARN of Lambda Execution Role |
| `lambda_execution_role_name` | Name of Lambda Execution Role |
| `lambda_deployment_role_arn` | ARN of Lambda Deployment Role |
| `lambda_deployment_role_name` | Name of Lambda Deployment Role |

## 🚀 Usage

### In Terraform Configuration

```hcl
module "iam" {
  source = "./modules/iam"
  
  aws_region                   = var.aws_region
  terraform_state_bucket_arn   = data.terraform_remote_state.global.outputs.terraform_state_bucket_arn
  terraform_locks_table_arn    = data.terraform_remote_state.global.outputs.terraform_locks_table_arn
  github_repository            = var.github_repository
  github_branch                = var.github_branch
}
```

### In GitHub Actions

```yaml
- name: Assume Infrastructure Role
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: ${{ secrets.AWS_INFRASTRUCTURE_ROLE_ARN }}
    aws-region: us-east-1

- name: Assume Lambda Deployment Role
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: ${{ secrets.AWS_LAMBDA_DEPLOYMENT_ROLE_ARN }}
    aws-region: us-east-1
```

## 🔄 OIDC Trust Relationship

The GitHub OIDC trust relationships use the following conditions:

```
Repository: repo:{github_repository}:ref:refs/heads/{github_branch}
```

This ensures:
- Only the specified GitHub repository can assume the role
- Only the specified branch can assume the role
- Other repositories or branches cannot use these roles

## 📊 Permission Details

### Infrastructure_Role Permissions

**S3 State Management**:
- `s3:ListBucket` - List state bucket contents
- `s3:GetBucketVersioning` - Check versioning status
- `s3:GetBucketLocation` - Get bucket location
- `s3:GetObject` - Read state files
- `s3:PutObject` - Write state files
- `s3:DeleteObject` - Delete state files

**DynamoDB State Locking**:
- `dynamodb:DescribeTable` - Check table status
- `dynamodb:GetItem` - Read lock
- `dynamodb:PutItem` - Create lock
- `dynamodb:DeleteItem` - Release lock

**API Gateway**:
- `apigateway:*` - Full API Gateway management

**Lambda**:
- Create, delete, update functions
- Manage permissions and aliases
- Publish versions

**DynamoDB Tables**:
- Create, delete, update tables
- Manage GSIs
- Tag resources

**IAM Roles**:
- Create, delete, update roles
- Manage trust relationships
- Attach/detach policies

**CloudWatch Logs**:
- Create log groups
- Set retention policies

**KMS**:
- Decrypt and generate data keys
- Limited to S3 and DynamoDB services

### Lambda_Execution_Role Permissions

**DynamoDB**:
- `dynamodb:GetItem` - Read single item
- `dynamodb:PutItem` - Create item
- `dynamodb:UpdateItem` - Update item
- `dynamodb:DeleteItem` - Delete item
- `dynamodb:Query` - Query items
- `dynamodb:Scan` - Scan table

**CloudWatch Logs**:
- `logs:CreateLogGroup` - Create log group
- `logs:CreateLogStream` - Create log stream
- `logs:PutLogEvents` - Write logs

**X-Ray** (optional):
- `xray:PutTraceSegments` - Write trace data
- `xray:PutTelemetryRecords` - Write telemetry

### Lambda_Deployment_Role Permissions

**S3**:
- `s3:PutObject` - Upload Lambda code
- `s3:GetObject` - Download Lambda code

**Lambda**:
- `lambda:UpdateFunctionCode` - Update code
- `lambda:UpdateFunctionConfiguration` - Update config
- `lambda:GetFunction` - Get function details

**CloudWatch Logs**:
- `logs:CreateLogGroup` - Create deployment logs
- `logs:CreateLogStream` - Create log stream
- `logs:PutLogEvents` - Write logs

## 🆘 Troubleshooting

### GitHub Actions Role Assumption Fails

**Cause**: OIDC provider not configured or trust relationship incorrect

**Solution**:
1. Verify OIDC provider exists in AWS IAM
2. Check trust relationship conditions match repository and branch
3. Verify GitHub Actions has `id-token: write` permission

### Lambda Execution Fails

**Cause**: Lambda Execution Role missing permissions

**Solution**:
1. Check DynamoDB table name matches policy
2. Verify CloudWatch Logs permissions
3. Check KMS key permissions if using encryption

### Terraform Apply Fails

**Cause**: Infrastructure Role missing permissions

**Solution**:
1. Check S3 bucket and DynamoDB table names
2. Verify IAM permissions for role creation
3. Check CloudWatch Logs permissions

## 📞 Support

For issues:
1. Check CloudTrail for API errors
2. Verify IAM role trust relationships
3. Review CloudWatch Logs for Lambda execution errors
4. Check GitHub Actions workflow logs for OIDC errors
