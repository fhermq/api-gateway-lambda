# Infrastructure Scripts

This directory contains utility scripts for managing, validating, and optimizing the Terraform infrastructure. All scripts are designed to be run from the project root directory.

## Overview

The infrastructure scripts provide automated validation, cost analysis, and resource management capabilities. Scripts are numbered to indicate execution order:

- **01-post-deployment-validation.sh** - Validates all resources after `terraform apply`
- **02-validate-infrastructure.sh** - Validates Terraform configuration syntax and structure
- **03-detect-orphaned-resources.sh** - Identifies AWS resources not managed by Terraform
- **04-cost-analysis.sh** - Estimates monthly costs and identifies optimization opportunities
- **05-destroy-validation.sh** - Validates infrastructure safety before destruction
- **06-cleanup-s3-buckets.sh** - Safely deletes S3 buckets with versioning enabled
- **07-destroy-environment.sh** - Complete environment destruction with cleanup

## Requirements

- Bash 4.0+
- Terraform 1.0+
- AWS CLI v2
- AWS credentials configured (for some scripts)
- `bc` command for calculations

## Installation

Make scripts executable:

```bash
chmod +x infrastructure/scripts/*.sh
```

## Scripts

### 1. 01-post-deployment-validation.sh

Validates all infrastructure resources were created successfully after `terraform apply`.

**Usage:**
```bash
./infrastructure/scripts/01-post-deployment-validation.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to validate (default: dev)

**Validations:**
- ✅ Lambda function exists and is active
- ✅ DynamoDB table exists and is active
- ✅ API Gateway is accessible
- ✅ S3 bucket exists and is configured
- ✅ IAM role exists with policies
- ✅ CloudWatch log group exists
- ✅ Lambda function can be invoked
- ✅ API Gateway endpoints respond correctly

**Example:**
```bash
# Validate deployment for dev environment
./infrastructure/scripts/01-post-deployment-validation.sh dev

# Validate deployment for staging environment
./infrastructure/scripts/01-post-deployment-validation.sh staging

# Validate deployment for prod environment
./infrastructure/scripts/01-post-deployment-validation.sh prod
```

**Output:**
- Console output with resource details and test results
- Validation report saved to `post-deployment-validation-report-TIMESTAMP.txt`

**When to Run:**
- Immediately after `terraform apply` completes
- As part of CI/CD pipeline after infrastructure deployment
- To verify all resources are properly configured

**Example CI/CD Integration:**
```yaml
- name: Deploy Infrastructure
  run: terraform -chdir=infrastructure/environments/${{ matrix.environment }} apply -auto-approve

- name: Validate Deployment
  run: ./infrastructure/scripts/01-post-deployment-validation.sh ${{ matrix.environment }}
```

### 2. 02-validate-infrastructure.sh

Validates Terraform configuration syntax, structure, and IAM policies.

**Usage:**
```bash
./infrastructure/scripts/02-validate-infrastructure.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to validate (default: dev)

**Validations:**
- ✅ Terraform syntax validation for all modules
- ✅ Terraform code formatting validation
- ✅ Required variables validation
- ✅ Module outputs validation
- ✅ IAM policy validation for least privilege
- ✅ Backend configuration validation
- ✅ Module references validation
- ✅ Encryption configuration validation
- ✅ Resource tagging validation

**Example:**
```bash
# Validate dev environment
./infrastructure/scripts/02-validate-infrastructure.sh dev

# Validate staging environment
./infrastructure/scripts/02-validate-infrastructure.sh staging

# Validate prod environment
./infrastructure/scripts/02-validate-infrastructure.sh prod
```

**Output:**
- Console output with pass/fail status for each validation
- Validation report saved to `validation-report-TIMESTAMP.txt`

**Requirements Validated:**
- Requirement 2.1: Terraform configuration defines modules
- Requirement 2.2: Terraform configuration supports environment-specific configurations
- Requirement 6.1-6.7: IAM roles with least-privilege permissions

### 3. 03-detect-orphaned-resources.sh

Identifies AWS resources not managed by Terraform and untagged resources.

**Usage:**
```bash
./infrastructure/scripts/03-detect-orphaned-resources.sh [environment] [resource-type]
```

**Parameters:**
- `environment` (optional): Environment to check (default: dev)
- `resource-type` (optional): Type of resources to check (default: all)
  - `lambda` - Lambda functions only
  - `dynamodb` - DynamoDB tables only
  - `s3` - S3 buckets only
  - `security-groups` - Security groups only
  - `all` - All resource types

**Detections:**
- ✅ Orphaned Lambda functions
- ✅ Orphaned DynamoDB tables
- ✅ Orphaned S3 buckets
- ✅ Orphaned security groups
- ✅ Untagged resources
- ✅ Cost estimation for orphaned resources

**Example:**
```bash
# Check all resources in dev environment
./infrastructure/scripts/03-detect-orphaned-resources.sh dev all

# Check only Lambda functions in staging
./infrastructure/scripts/03-detect-orphaned-resources.sh staging lambda

# Check only DynamoDB tables in prod
./infrastructure/scripts/03-detect-orphaned-resources.sh prod dynamodb
```

**Output:**
- Console output with orphaned resources list
- Cost estimation for orphaned resources
- Detection report saved to `orphaned-resources-report-TIMESTAMP.txt`

**Requirements Validated:**
- Requirement 10.1: Infrastructure validation scripts
- Requirement 10.2: Orphaned resource detection
- Requirement 10.3: Cost-saving opportunities identification

### 4. 04-cost-analysis.sh

Estimates monthly costs and identifies cost optimization opportunities.

**Usage:**
```bash
./infrastructure/scripts/04-cost-analysis.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to analyze (default: dev)

**Cost Analysis:**
- ✅ Lambda function costs
- ✅ DynamoDB table costs
- ✅ S3 bucket costs
- ✅ CloudWatch logging costs
- ✅ API Gateway costs
- ✅ Total monthly and annual cost estimates

**Optimization Recommendations:**
- DynamoDB billing mode optimization
- S3 Intelligent-Tiering
- Lambda reserved concurrency
- CloudWatch Logs retention policies
- Unused resource cleanup

**Example:**
```bash
# Analyze costs for dev environment
./infrastructure/scripts/04-cost-analysis.sh dev

# Analyze costs for staging environment
./infrastructure/scripts/04-cost-analysis.sh staging

# Analyze costs for prod environment
./infrastructure/scripts/04-cost-analysis.sh prod
```

**Output:**
- Console output with cost breakdown
- Monthly and annual cost estimates
- Optimization recommendations
- Cost analysis report saved to `cost-analysis-report-TIMESTAMP.txt`

**Cost Breakdown Example:**
```
Lambda:       $10.50/month
DynamoDB:     $5.25/month
S3:           $1.00/month
CloudWatch:   $2.50/month
API Gateway:  $35.00/month
─────────────────────
Total:        $54.25/month

Annual Estimate: $651.00
```

**Requirements Validated:**
- Requirement 10.1: Infrastructure validation scripts
- Requirement 10.2: Cost analysis
- Requirement 10.3: Cost optimization recommendations

### 5. 05-destroy-validation.sh

Validates infrastructure safety before destruction and creates state backups.

**Usage:**
```bash
./infrastructure/scripts/05-destroy-validation.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to destroy (default: dev)

**Validations:**
- ✅ Environment validation (prevents accidental production destruction)
- ✅ Terraform state validation
- ✅ Resources to be destroyed review
- ✅ Data loss risk assessment
- ✅ External dependency validation
- ✅ Terraform state backup creation

**Safety Features:**
- Production environment requires explicit confirmation
- Data loss warnings for DynamoDB and S3
- Terraform state backup before destruction
- Confirmation prompts before proceeding

**Example:**
```bash
# Validate destruction for dev environment
./infrastructure/scripts/05-destroy-validation.sh dev

# Validate destruction for staging environment
./infrastructure/scripts/05-destroy-validation.sh staging

# Validate destruction for prod environment (requires confirmation)
./infrastructure/scripts/05-destroy-validation.sh prod
```

**Output:**
- Console output with validation results
- Terraform state backup saved to `state-backups/terraform-state-backup-TIMESTAMP.tar.gz`
- Confirmation prompts for safety

**Requirements Validated:**
- Requirement 10.1: Infrastructure validation scripts
- Requirement 10.2: Destruction validation
- Requirement 10.3: State backup creation

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Validate Infrastructure
  run: ./infrastructure/scripts/02-validate-infrastructure.sh ${{ matrix.environment }}

- name: Detect Orphaned Resources
  run: ./infrastructure/scripts/03-detect-orphaned-resources.sh ${{ matrix.environment }}

- name: Analyze Costs
  run: ./infrastructure/scripts/04-cost-analysis.sh ${{ matrix.environment }}
```

## Troubleshooting

### AWS Credentials Error

**Problem:** `AWS credentials not configured or invalid`

**Solution:**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

### Terraform Not Found

**Problem:** `terraform: command not found`

**Solution:**
```bash
# Install Terraform
brew install terraform  # macOS
# or
choco install terraform  # Windows
# or
apt-get install terraform  # Linux
```

### Permission Denied

**Problem:** `Permission denied: ./infrastructure/scripts/validate-infrastructure.sh`

**Solution:**
```bash
chmod +x infrastructure/scripts/*.sh
```

### AWS CLI Not Found

**Problem:** `AWS CLI not available - using default estimates`

**Solution:**
```bash
# Install AWS CLI v2
pip install awscli
# or
brew install awscli  # macOS
```

## Output Files

Scripts generate timestamped report files in the `infrastructure/scripts/` directory:

- `validation-report-YYYYMMDD-HHMMSS.txt` - Validation results
- `orphaned-resources-report-YYYYMMDD-HHMMSS.txt` - Orphaned resources list
- `cost-analysis-report-YYYYMMDD-HHMMSS.txt` - Cost analysis results
- `state-backups/terraform-state-backup-YYYYMMDD-HHMMSS.tar.gz` - State backup

## Best Practices

1. **Run Before Deployment**: Always run validation scripts before deploying infrastructure
2. **Regular Cost Analysis**: Run cost analysis monthly to track spending
3. **Orphaned Resource Detection**: Run weekly to identify unused resources
4. **Backup Before Destruction**: Always create backups before destroying infrastructure
5. **Environment-Specific**: Always specify the correct environment to avoid mistakes
6. **Review Reports**: Always review generated reports for issues

## Requirements Validation

These scripts validate the following requirements:

- **Requirement 2.1**: Terraform configuration defines modules
- **Requirement 2.2**: Terraform configuration supports environment-specific configurations
- **Requirement 6.1-6.7**: IAM roles with least-privilege permissions
- **Requirement 10.1**: Infrastructure validation scripts
- **Requirement 10.2**: Orphaned resource detection
- **Requirement 10.3**: Cost analysis and optimization

## See Also

- [Infrastructure README](../README.md)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)


### 6. 06-cleanup-s3-buckets.sh

Safely deletes S3 buckets that have versioning enabled by removing all versions and delete markers.

**Usage:**
```bash
./infrastructure/scripts/06-cleanup-s3-buckets.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to clean (default: dev)
  - `dev` - Clean dev environment S3 buckets
  - `staging` - Clean staging environment S3 buckets
  - `prod` - Clean prod environment S3 buckets
  - `global` - Clean global Terraform state buckets
  - `all` - Clean all buckets

**Cleanup Process:**
1. Lists all object versions in the bucket
2. Deletes each version individually
3. Deletes all delete markers
4. Deletes the empty bucket

**Example:**
```bash
# Clean dev environment S3 buckets
./infrastructure/scripts/06-cleanup-s3-buckets.sh dev

# Clean staging environment S3 buckets
./infrastructure/scripts/06-cleanup-s3-buckets.sh staging

# Clean prod environment S3 buckets
./infrastructure/scripts/06-cleanup-s3-buckets.sh prod

# Clean global Terraform state buckets
./infrastructure/scripts/06-cleanup-s3-buckets.sh global
```

**Output:**
- Console output showing each deleted version
- Success/failure status for each bucket
- Final summary of cleanup results

**Why This Script Exists:**
- Terraform `destroy` cannot delete S3 buckets with versioning enabled
- Manual cleanup of versioned objects is tedious and error-prone
- This script automates the safe deletion process

### 7. 07-destroy-environment.sh

Complete environment destruction workflow that safely destroys all infrastructure.

**Usage:**
```bash
./infrastructure/scripts/07-destroy-environment.sh [environment]
```

**Parameters:**
- `environment` (optional): Environment to destroy (default: dev)

**Destruction Workflow:**
1. Validates destruction safety (prevents accidental production destruction)
2. Creates Terraform state backup
3. Runs `terraform destroy` with auto-approval
4. Cleans up S3 buckets with versioning
5. Detects any remaining orphaned resources
6. Generates cleanup report

**Example:**
```bash
# Destroy dev environment
./infrastructure/scripts/07-destroy-environment.sh dev

# Destroy staging environment
./infrastructure/scripts/07-destroy-environment.sh staging

# Destroy prod environment (requires confirmation)
./infrastructure/scripts/07-destroy-environment.sh prod
```

**Safety Features:**
- Requires explicit confirmation before proceeding
- Validates environment before destruction
- Creates state backup before destruction
- Detects orphaned resources after destruction
- Prevents accidental production destruction

**Output:**
- Step-by-step progress output
- Terraform destroy logs
- S3 bucket cleanup logs
- Orphaned resources report
- Final summary with next steps

**When to Use:**
- Cleaning up development/staging environments
- Decommissioning infrastructure
- Testing destruction workflows
- Preparing for infrastructure redesign

## Complete Destruction Workflow

To safely destroy an entire environment:

```bash
# Step 1: Validate safety
./infrastructure/scripts/05-destroy-validation.sh dev

# Step 2: Run complete destruction
./infrastructure/scripts/07-destroy-environment.sh dev

# Step 3: Verify cleanup
./infrastructure/scripts/03-detect-orphaned-resources.sh dev all
```

Or use the all-in-one script:

```bash
./infrastructure/scripts/07-destroy-environment.sh dev
```

## S3 Bucket Lifecycle Policies

To ensure automatic cleanup of old versions and prevent future issues:

**Lifecycle Policy Features:**
- Automatically delete old object versions after 7 days
- Automatically delete expired delete markers
- Reduce storage costs
- Enable safe bucket deletion

**Configured On:**
- Lambda code buckets (dev, staging, prod)
- Lambda logs buckets (dev, staging, prod)
- Terraform state bucket (global)
- Terraform logs bucket (global)

**Benefits:**
- Automatic cleanup of old versions
- Reduced S3 storage costs
- Easier bucket deletion during destruction
- Compliance with retention policies
