#!/bin/bash

################################################################################
# Post-Deployment Validation Script
# 
# Purpose: Validate all deployed AWS resources after terraform apply
# Usage: ./01-post-deployment-validation.sh [environment]
# 
# This script validates:
# - Deployed DynamoDB table
# - Deployed S3 bucket
# - Deployed IAM roles
# - Deployed Lambda function (if available)
# - Deployed API Gateway (if available)
# - CloudWatch log groups
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="${1:-dev}"

echo ""
echo "========================================"
echo "Post-Deployment Validation Script"
echo "========================================"
echo ""

echo -e "${BLUE}ℹ️  Starting post-deployment validation for environment: $ENVIRONMENT${NC}"
echo ""

# Get AWS info
AWS_REGION=$(aws configure get region || echo "us-east-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${BLUE}ℹ️  AWS Account: $ACCOUNT_ID${NC}"
echo -e "${BLUE}ℹ️  AWS Region: $AWS_REGION${NC}"
echo ""

# 1. DynamoDB Table
echo "--- DynamoDB Table Validation ---"
echo ""

table_name="serverless-monorepo-items-$ENVIRONMENT"
if aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" > /dev/null 2>&1; then
    status=$(aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" --query 'Table.TableStatus' --output text)
    echo -e "${GREEN}✅ DynamoDB table '$table_name' exists${NC}"
    echo -e "${BLUE}   Status: $status${NC}"
    
    # Get table details
    item_count=$(aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" --query 'Table.ItemCount' --output text)
    table_size=$(aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" --query 'Table.TableSizeBytes' --output text)
    echo -e "${BLUE}   Items: $item_count${NC}"
    echo -e "${BLUE}   Size: $((table_size / 1024))KB${NC}"
else
    echo -e "${RED}❌ DynamoDB table '$table_name' not found${NC}"
fi

echo ""

# 2. S3 Bucket
echo "--- S3 Bucket Validation ---"
echo ""

bucket_name="serverless-monorepo-lambda-code-$ENVIRONMENT-$ACCOUNT_ID"
if aws s3 ls "s3://$bucket_name" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ S3 bucket '$bucket_name' exists${NC}"
    
    # Get bucket details
    versioning=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --region "$AWS_REGION" --query 'Status' --output text 2>/dev/null || echo "Not enabled")
    echo -e "${BLUE}   Versioning: $versioning${NC}"
else
    echo -e "${RED}❌ S3 bucket '$bucket_name' not found${NC}"
fi

echo ""

# 3. IAM Roles
echo "--- IAM Roles Validation ---"
echo ""

for role in "Infrastructure_Role" "Lambda_Execution_Role" "Lambda_Deployment_Role"; do
    if aws iam get-role --role-name "$role" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ IAM role '$role' exists${NC}"
        
        # Get attached policies count
        policy_count=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies | length(@)' --output text)
        echo -e "${BLUE}   Attached policies: $policy_count${NC}"
    else
        echo -e "${YELLOW}⚠️  IAM role '$role' not found${NC}"
    fi
done

echo ""

# 4. Lambda Function (if deployed)
echo "--- Lambda Function Validation ---"
echo ""

lambda_name="api-handler-$ENVIRONMENT"
if aws lambda get-function --function-name "$lambda_name" --region "$AWS_REGION" > /dev/null 2>&1; then
    state=$(aws lambda get-function --function-name "$lambda_name" --region "$AWS_REGION" --query 'Configuration.State' --output text)
    runtime=$(aws lambda get-function --function-name "$lambda_name" --region "$AWS_REGION" --query 'Configuration.Runtime' --output text)
    memory=$(aws lambda get-function --function-name "$lambda_name" --region "$AWS_REGION" --query 'Configuration.MemorySize' --output text)
    
    echo -e "${GREEN}✅ Lambda function '$lambda_name' exists${NC}"
    echo -e "${BLUE}   State: $state${NC}"
    echo -e "${BLUE}   Runtime: $runtime${NC}"
    echo -e "${BLUE}   Memory: ${memory}MB${NC}"
else
    echo -e "${YELLOW}⚠️  Lambda function '$lambda_name' not found (may not be deployed yet)${NC}"
fi

echo ""

# 5. API Gateway (if deployed)
echo "--- API Gateway Validation ---"
echo ""

api_name="serverless-monorepo-api-$ENVIRONMENT"
api_id=$(aws apigateway get-rest-apis --region "$AWS_REGION" --query "items[?name=='$api_name'].id" --output text 2>/dev/null || echo "")

if [ -n "$api_id" ]; then
    echo -e "${GREEN}✅ API Gateway '$api_name' exists${NC}"
    echo -e "${BLUE}   API ID: $api_id${NC}"
    
    # Get resources count
    resources=$(aws apigateway get-resources --rest-api-id "$api_id" --region "$AWS_REGION" --query 'items | length(@)' --output text)
    echo -e "${BLUE}   Resources: $resources${NC}"
else
    echo -e "${YELLOW}⚠️  API Gateway '$api_name' not found (may not be deployed yet)${NC}"
fi

echo ""

# 6. CloudWatch Log Groups
echo "--- CloudWatch Log Groups Validation ---"
echo ""

log_groups=(
    "/aws/lambda/api-handler-$ENVIRONMENT"
    "/aws/apigateway/serverless-monorepo-$ENVIRONMENT"
)

for log_group in "${log_groups[@]}"; do
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$AWS_REGION" --query "logGroups[?logGroupName=='$log_group'].logGroupName" --output text 2>/dev/null | grep -q "$log_group"; then
        echo -e "${GREEN}✅ Log group '$log_group' exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Log group '$log_group' not found${NC}"
    fi
done

echo ""
echo "========================================"
echo "Post-Deployment Validation Complete"
echo "========================================"
echo ""
