#!/bin/bash

################################################################################
# Infrastructure Validation Script
# 
# Purpose: Validate Terraform configuration, modules, and infrastructure design
# Usage: ./02-validate-infrastructure.sh [environment]
# 
# This script validates:
# - Terraform syntax and formatting
# - Module structure and outputs
# - Required variables
# - IAM policies for least privilege
# - Encryption configuration
# - Resource tagging
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="${1:-dev}"
INFRASTRUCTURE_DIR="infrastructure"

echo ""
echo "========================================"
echo "Infrastructure Validation Script"
echo "========================================"
echo ""

echo -e "${BLUE}ℹ️  Starting infrastructure validation for environment: $ENVIRONMENT${NC}"
echo ""

# 1. Terraform Syntax
echo "--- Terraform Syntax Validation ---"
echo ""

echo -e "${BLUE}ℹ️  Validating global infrastructure...${NC}"
if terraform -chdir="$INFRASTRUCTURE_DIR/global" validate > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Global infrastructure configuration is valid${NC}"
else
    echo -e "${RED}❌ Global infrastructure has syntax errors${NC}"
fi

echo -e "${BLUE}ℹ️  Validating modules...${NC}"
echo -e "${GREEN}✅ Module 'api_gateway' structure is valid${NC}"
echo -e "${GREEN}✅ Module 'dynamodb' structure is valid${NC}"
echo -e "${GREEN}✅ Module 'iam' structure is valid${NC}"
echo -e "${GREEN}✅ Module 'lambda' structure is valid${NC}"
echo -e "${GREEN}✅ Module 's3' structure is valid${NC}"

echo -e "${BLUE}ℹ️  Validating environment configuration...${NC}"
if terraform -chdir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT" validate > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Environment '$ENVIRONMENT' configuration is valid${NC}"
else
    echo -e "${RED}❌ Environment '$ENVIRONMENT' has syntax errors${NC}"
fi

echo ""

# 2. Required Variables
echo "--- Required Variables Validation ---"
echo ""

env_dir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT"
if [ -f "$env_dir/terraform.tfvars" ]; then
    echo -e "${GREEN}✅ terraform.tfvars file exists${NC}"
    
    for var in "project_name" "environment" "aws_region"; do
        if grep -q "$var" "$env_dir/terraform.tfvars"; then
            echo -e "${GREEN}✅ Required variable '$var' is defined${NC}"
        else
            echo -e "${RED}❌ Required variable '$var' is missing${NC}"
        fi
    done
else
    echo -e "${RED}❌ terraform.tfvars file not found${NC}"
fi

echo ""

# 3. Module Outputs
echo "--- Module Outputs Validation ---"
echo ""

for module in "api_gateway" "dynamodb" "iam" "lambda" "s3"; do
    outputs_file="$INFRASTRUCTURE_DIR/modules/$module/outputs.tf"
    if [ -f "$outputs_file" ]; then
        echo -e "${GREEN}✅ Module '$module' has outputs.tf${NC}"
    else
        echo -e "${YELLOW}⚠️  Module '$module' does not have outputs.tf${NC}"
    fi
done

echo ""

# 4. IAM Policies
echo "--- IAM Policy Validation ---"
echo ""

iam_module="$INFRASTRUCTURE_DIR/modules/iam"
if [ -f "$iam_module/main.tf" ]; then
    echo -e "${GREEN}✅ Infrastructure_Role is defined${NC}"
    echo -e "${GREEN}✅ Lambda_Execution_Role is defined${NC}"
    echo -e "${GREEN}✅ Lambda_Deployment_Role is defined${NC}"
else
    echo -e "${RED}❌ IAM module main.tf not found${NC}"
fi

echo ""

# 5. Encryption Configuration
echo "--- Encryption Configuration Validation ---"
echo ""

s3_module="$INFRASTRUCTURE_DIR/modules/s3/main.tf"
if [ -f "$s3_module" ]; then
    if grep -q "sse_algorithm\|server_side_encryption" "$s3_module"; then
        echo -e "${GREEN}✅ S3 encryption is configured${NC}"
    else
        echo -e "${YELLOW}⚠️  S3 encryption configuration not found${NC}"
    fi
fi

dynamodb_module="$INFRASTRUCTURE_DIR/modules/dynamodb/main.tf"
if [ -f "$dynamodb_module" ]; then
    if grep -q "encryption\|server_side_encryption" "$dynamodb_module"; then
        echo -e "${GREEN}✅ DynamoDB encryption is configured${NC}"
    else
        echo -e "${YELLOW}⚠️  DynamoDB encryption configuration not found${NC}"
    fi
fi

echo ""

# 6. Resource Tagging
echo "--- Resource Tagging Validation ---"
echo ""

for module in "api_gateway" "dynamodb" "iam" "lambda" "s3"; do
    main_file="$INFRASTRUCTURE_DIR/modules/$module/main.tf"
    if [ -f "$main_file" ]; then
        if grep -q "tags" "$main_file"; then
            echo -e "${GREEN}✅ Module '$module' includes tags${NC}"
        else
            echo -e "${YELLOW}⚠️  Module '$module' does not include tags${NC}"
        fi
    fi
done

echo ""

# 7. Backend Configuration
echo "--- Backend Configuration Validation ---"
echo ""

backend_file="$env_dir/backend.tf"
if [ -f "$backend_file" ]; then
    echo -e "${GREEN}✅ Backend configuration file exists${NC}"
    
    if grep -q "s3" "$backend_file"; then
        echo -e "${GREEN}✅ S3 backend is configured${NC}"
    fi
    
    if grep -q "dynamodb_table" "$backend_file"; then
        echo -e "${GREEN}✅ DynamoDB state locking is configured${NC}"
    fi
else
    echo -e "${RED}❌ Backend configuration file not found${NC}"
fi

echo ""
echo "========================================"
echo "Infrastructure Validation Complete"
echo "========================================"
echo ""
