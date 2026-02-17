# GitHub Actions Setup Guide

## Overview

This guide consolidates all prerequisites needed to make GitHub Actions workflows succeed. The workflows failed because AWS resources and GitHub Secrets weren't configured yet. This is **normal and expected**.

---

## Quick Start (5-10 minutes)

### Step 1: Get Your AWS Account ID (1 minute)

```bash
aws sts get-caller-identity --query Account --output text
# Output: 123456789012 (copy this)
```

### Step 2: Add GitHub Secret (2 minutes)

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. **Name**: `AWS_ACCOUNT_ID`
5. **Value**: Paste your AWS account ID from Step 1
6. Click **Add secret**

### Step 3: Create AWS Resources (5 minutes)

Copy and run this script to create all necessary AWS resources:

```bash
#!/bin/bash

# Get repository info
REPO_URL=$(git config --get remote.origin.url)
REPO_OWNER=$(echo $REPO_URL | sed 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\1/')
REPO_NAME=$(echo $REPO_URL | sed 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\2/')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Setting up GitHub Actions prerequisites..."
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Account ID: $ACCOUNT_ID"
echo ""

# 1. Create OIDC Provider
echo "1. Creating GitHub OIDC Provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null && echo "   ✅ Created" || echo "   ℹ️  Already exists"

# 2. Create Infrastructure_Role
echo "2. Creating Infrastructure_Role..."
aws iam create-role \
  --role-name Infrastructure_Role \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Federated\": \"arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com\"},
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringEquals\": {\"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"},
        \"StringLike\": {\"token.actions.githubusercontent.com:sub\": \"repo:$REPO_OWNER/$REPO_NAME:ref:refs/heads/main\"}
      }
    }]
  }" 2>/dev/null && echo "   ✅ Created" || echo "   ℹ️  Already exists"

aws iam put-role-policy \
  --role-name Infrastructure_Role \
  --policy-name TerraformPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:*", "dynamodb:*", "apigateway:*", "lambda:*", "iam:*", "cloudwatch:*", "logs:*", "kms:*"],
      "Resource": "*"
    }]
  }' && echo "   ✅ Policy attached"

# 3. Create Lambda_Deployment_Role
echo "3. Creating Lambda_Deployment_Role..."
aws iam create-role \
  --role-name Lambda_Deployment_Role \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Federated\": \"arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com\"},
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringEquals\": {\"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"},
        \"StringLike\": {\"token.actions.githubusercontent.com:sub\": \"repo:$REPO_OWNER/$REPO_NAME:ref:refs/heads/main\"}
      }
    }]
  }" 2>/dev/null && echo "   ✅ Created" || echo "   ℹ️  Already exists"

aws iam put-role-policy \
  --role-name Lambda_Deployment_Role \
  --policy-name LambdaDeploymentPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "lambda:UpdateFunctionCode", "lambda:GetFunction", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "*"
    }]
  }' && echo "   ✅ Policy attached"

# 4. Create CloudWatch Log Groups
echo "4. Creating CloudWatch Log Groups..."
aws logs create-log-group --log-group-name /aws/github-actions/infrastructure 2>/dev/null && echo "   ✅ Infrastructure log group created" || echo "   ℹ️  Already exists"
aws logs create-log-group --log-group-name /aws/github-actions/lambda 2>/dev/null && echo "   ✅ Lambda log group created" || echo "   ℹ️  Already exists"

aws logs put-retention-policy --log-group-name /aws/github-actions/infrastructure --retention-in-days 7
aws logs put-retention-policy --log-group-name /aws/github-actions/lambda --retention-in-days 7

echo ""
echo "✅ AWS setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify GitHub Secret AWS_ACCOUNT_ID is set"
echo "2. Re-run workflows in GitHub Actions"
echo "3. Monitor CloudWatch logs"
```

---

## Verification Checklist

After setup, verify everything is configured:

```bash
#!/bin/bash

echo "🔍 Verifying GitHub Actions Setup..."
echo ""

# 1. Check GitHub Secret
echo "1. GitHub Secret AWS_ACCOUNT_ID:"
echo "   Go to: Settings → Secrets and variables → Actions"
echo "   Should see: AWS_ACCOUNT_ID ✅"
echo ""

# 2. Check AWS Roles
echo "2. AWS IAM Roles:"
aws iam get-role --role-name Infrastructure_Role >/dev/null 2>&1 && echo "   ✅ Infrastructure_Role exists" || echo "   ❌ Infrastructure_Role missing"
aws iam get-role --role-name Lambda_Deployment_Role >/dev/null 2>&1 && echo "   ✅ Lambda_Deployment_Role exists" || echo "   ❌ Lambda_Deployment_Role missing"
echo ""

# 3. Check OIDC Provider
echo "3. GitHub OIDC Provider:"
aws iam list-open-id-connect-providers | grep -q "token.actions.githubusercontent.com" && echo "   ✅ OIDC Provider exists" || echo "   ❌ OIDC Provider missing"
echo ""

# 4. Check Log Groups
echo "4. CloudWatch Log Groups:"
aws logs describe-log-groups --log-group-name-prefix /aws/github-actions/ 2>/dev/null | grep -q "infrastructure" && echo "   ✅ Infrastructure log group exists" || echo "   ❌ Infrastructure log group missing"
aws logs describe-log-groups --log-group-name-prefix /aws/github-actions/ 2>/dev/null | grep -q "lambda" && echo "   ✅ Lambda log group exists" || echo "   ❌ Lambda log group missing"
echo ""

# 5. Check Trust Relationships
echo "5. Trust Relationships:"
REPO_URL=$(git config --get remote.origin.url)
REPO_OWNER=$(echo $REPO_URL | sed 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\1/')
REPO_NAME=$(echo $REPO_URL | sed 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\2/')

aws iam get-role --role-name Infrastructure_Role --query 'Role.AssumeRolePolicyDocument' 2>/dev/null | grep -q "$REPO_OWNER/$REPO_NAME" && echo "   ✅ Infrastructure_Role trust relationship correct" || echo "   ❌ Infrastructure_Role trust relationship incorrect"
aws iam get-role --role-name Lambda_Deployment_Role --query 'Role.AssumeRolePolicyDocument' 2>/dev/null | grep -q "$REPO_OWNER/$REPO_NAME" && echo "   ✅ Lambda_Deployment_Role trust relationship correct" || echo "   ❌ Lambda_Deployment_Role trust relationship incorrect"
echo ""

echo "✅ Verification complete"
```

---

## What Each Component Does

### GitHub Secret: `AWS_ACCOUNT_ID`
- **Purpose**: Allows workflows to know which AWS account to deploy to
- **Value**: Your 12-digit AWS account ID
- **Used by**: Both infrastructure and Lambda deployment workflows

### AWS IAM Role: `Infrastructure_Role`
- **Purpose**: Allows GitHub Actions to deploy infrastructure via Terraform
- **Permissions**: S3, DynamoDB, API Gateway, Lambda, IAM, CloudWatch, KMS
- **Restrictions**: Only from your repository, main branch
- **Used by**: Infrastructure Provisioning workflow

### AWS IAM Role: `Lambda_Deployment_Role`
- **Purpose**: Allows GitHub Actions to deploy Lambda code updates
- **Permissions**: S3 (get/put), Lambda (update code), CloudWatch Logs
- **Restrictions**: Only from your repository, main branch
- **Used by**: Lambda Deployment workflow

### GitHub OIDC Provider
- **Purpose**: Establishes trust between GitHub and AWS
- **URL**: `https://token.actions.githubusercontent.com`
- **Benefit**: No long-lived credentials needed, automatic token rotation
- **Status**: Usually already exists from Task 4

### CloudWatch Log Groups
- **Purpose**: Capture logs from GitHub Actions workflows
- **Groups**:
  - `/aws/github-actions/infrastructure` - Infrastructure deployment logs
  - `/aws/github-actions/lambda` - Lambda deployment logs
- **Retention**: 7 days

---

## Testing Workflows

After setup, test the workflows:

### Test Infrastructure Workflow

```bash
# Make a small change
echo "# Test" >> infrastructure/README.md

# Commit and push
git add infrastructure/README.md
git commit -m "Test infrastructure workflow"
git push origin main

# Watch workflow
# Go to: GitHub → Actions → Infrastructure Provisioning
# Wait for workflow to complete
```

### Test Lambda Workflow

```bash
# Make a small change
echo "# Test" >> apps/api-handler/README.md

# Commit and push
git add apps/api-handler/README.md
git commit -m "Test lambda workflow"
git push origin main

# Watch workflow
# Go to: GitHub → Actions → Lambda Deployment
# Wait for workflow to complete
```

### Monitor Logs

```bash
# Watch infrastructure deployment
aws logs tail /aws/github-actions/infrastructure --follow

# Watch lambda deployment
aws logs tail /aws/github-actions/lambda --follow
```

---

## Troubleshooting

### Error: "Unable to assume role"

**Cause**: OIDC trust relationship not configured correctly

**Solution**:
```bash
# Verify trust policy includes your repository
aws iam get-role --role-name Infrastructure_Role \
  --query 'Role.AssumeRolePolicyDocument' | jq .

# Should show your repository in the condition:
# "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"
```

### Error: "Secret AWS_ACCOUNT_ID not found"

**Cause**: GitHub Secret not configured

**Solution**:
1. Go to GitHub → Settings → Secrets and variables → Actions
2. Click **New repository secret**
3. Add `AWS_ACCOUNT_ID` with your AWS account ID

### Error: "Access Denied" in CloudWatch logs

**Cause**: IAM role doesn't have required permissions

**Solution**:
```bash
# Verify role has policies attached
aws iam list-role-policies --role-name Infrastructure_Role
aws iam list-role-policies --role-name Lambda_Deployment_Role

# If empty, re-run the setup script to attach policies
```

### Error: "OIDC Provider not found"

**Cause**: GitHub OIDC Provider not created in AWS

**Solution**:
```bash
# Create OIDC Provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Workflow fails but no error message

**Solution**:
1. Check CloudWatch logs:
   ```bash
   aws logs tail /aws/github-actions/infrastructure --follow
   aws logs tail /aws/github-actions/lambda --follow
   ```
2. Check GitHub Actions workflow logs (click on the failed workflow)
3. Verify all prerequisites are configured (run verification script above)

---

## Manual Setup (If Script Doesn't Work)

If the script fails, you can create resources manually:

### Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create Infrastructure_Role

```bash
# Get your info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_OWNER="your-github-org"
REPO_NAME="your-repo-name"

# Create role
aws iam create-role \
  --role-name Infrastructure_Role \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Federated\": \"arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com\"},
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringEquals\": {\"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"},
        \"StringLike\": {\"token.actions.githubusercontent.com:sub\": \"repo:$REPO_OWNER/$REPO_NAME:ref:refs/heads/main\"}
      }
    }]
  }"

# Attach policy
aws iam put-role-policy \
  --role-name Infrastructure_Role \
  --policy-name TerraformPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:*", "dynamodb:*", "apigateway:*", "lambda:*", "iam:*", "cloudwatch:*", "logs:*", "kms:*"],
      "Resource": "*"
    }]
  }'
```

### Create Lambda_Deployment_Role

```bash
# Get your info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_OWNER="your-github-org"
REPO_NAME="your-repo-name"

# Create role
aws iam create-role \
  --role-name Lambda_Deployment_Role \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Federated\": \"arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com\"},
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringEquals\": {\"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"},
        \"StringLike\": {\"token.actions.githubusercontent.com:sub\": \"repo:$REPO_OWNER/$REPO_NAME:ref:refs/heads/main\"}
      }
    }]
  }"

# Attach policy
aws iam put-role-policy \
  --role-name Lambda_Deployment_Role \
  --policy-name LambdaDeploymentPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "lambda:UpdateFunctionCode", "lambda:GetFunction", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "*"
    }]
  }'
```

### Create CloudWatch Log Groups

```bash
aws logs create-log-group --log-group-name /aws/github-actions/infrastructure
aws logs create-log-group --log-group-name /aws/github-actions/lambda

aws logs put-retention-policy --log-group-name /aws/github-actions/infrastructure --retention-in-days 7
aws logs put-retention-policy --log-group-name /aws/github-actions/lambda --retention-in-days 7
```

---

## Summary Checklist

- [ ] GitHub Secret `AWS_ACCOUNT_ID` created
- [ ] AWS IAM role `Infrastructure_Role` created
- [ ] AWS IAM role `Lambda_Deployment_Role` created
- [ ] GitHub OIDC Provider exists
- [ ] Trust relationships configured for both roles
- [ ] CloudWatch log groups created
- [ ] Infrastructure workflow tested successfully
- [ ] Lambda workflow tested successfully

---

## Next Steps

1. **Run the setup script** (copy from Quick Start section)
2. **Add GitHub Secret** `AWS_ACCOUNT_ID`
3. **Re-run workflows** in GitHub Actions
4. **Monitor logs** in CloudWatch
5. **Verify resources** were created in AWS

---

**Last Updated**: February 17, 2026
**Time to Setup**: 5-10 minutes
**Status**: Comprehensive Setup Guide
