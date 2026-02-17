#!/bin/bash

################################################################################
# Detect Orphaned Resources Script
# 
# Purpose: Identify AWS resources not managed by Terraform
# Usage: ./detect-orphaned-resources.sh [environment] [resource-type]
# 
# Requirements: 10.1, 10.2, 10.3
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRASTRUCTURE_DIR="$PROJECT_ROOT/infrastructure"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$SCRIPT_DIR/orphaned-resources-report-$TIMESTAMP.txt"

# Parameters
ENVIRONMENT="${1:-dev}"
RESOURCE_TYPE="${2:-all}"

# Counters
ORPHANED_COUNT=0
UNTAGGED_COUNT=0

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

print_section() {
    echo ""
    echo "--- $1 ---"
    echo ""
}

################################################################################
# Validation Functions
################################################################################

check_aws_credentials() {
    print_section "Checking AWS Credentials"
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid"
        log_info "Please configure AWS credentials using 'aws configure'"
        exit 1
    fi
    
    log_success "AWS credentials are valid"
    
    # Get account ID and region
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region || echo "us-east-1")
    
    log_info "AWS Account: $ACCOUNT_ID"
    log_info "AWS Region: $AWS_REGION"
}

detect_orphaned_lambda_functions() {
    print_section "Detecting Orphaned Lambda Functions"
    
    log_info "Scanning for Lambda functions not managed by Terraform..."
    
    # Get all Lambda functions
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text)
    
    if [ -z "$functions" ]; then
        log_success "No Lambda functions found"
        return
    fi
    
    # Check each function
    for function in $functions; do
        # Check if function is in Terraform state
        if ! terraform -chdir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT" state list | grep -q "aws_lambda_function.*$function"; then
            log_warning "Orphaned Lambda function found: $function"
            ((ORPHANED_COUNT++))
            
            # Get function details
            tags=$(aws lambda list-tags-by-resource --resource-arn "arn:aws:lambda:$AWS_REGION:$ACCOUNT_ID:function:$function" --query 'Tags' --output json 2>/dev/null || echo "{}")
            
            if [ "$tags" = "{}" ]; then
                log_warning "  - No tags found (potential cost)"
                ((UNTAGGED_COUNT++))
            fi
        fi
    done
}

detect_orphaned_dynamodb_tables() {
    print_section "Detecting Orphaned DynamoDB Tables"
    
    log_info "Scanning for DynamoDB tables not managed by Terraform..."
    
    # Get all DynamoDB tables
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text)
    
    if [ -z "$tables" ]; then
        log_success "No DynamoDB tables found"
        return
    fi
    
    # Check each table
    for table in $tables; do
        # Check if table is in Terraform state
        if ! terraform -chdir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT" state list | grep -q "aws_dynamodb_table.*$table"; then
            log_warning "Orphaned DynamoDB table found: $table"
            ((ORPHANED_COUNT++))
            
            # Get table size
            size=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" --query 'Table.TableSizeBytes' --output text)
            log_info "  - Table size: $((size / 1024 / 1024)) MB"
        fi
    done
}

detect_orphaned_s3_buckets() {
    print_section "Detecting Orphaned S3 Buckets"
    
    log_info "Scanning for S3 buckets not managed by Terraform..."
    
    # Get all S3 buckets
    buckets=$(aws s3 ls --query 'Buckets[].Name' --output text)
    
    if [ -z "$buckets" ]; then
        log_success "No S3 buckets found"
        return
    fi
    
    # Check each bucket
    for bucket in $buckets; do
        # Check if bucket is in Terraform state
        if ! terraform -chdir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT" state list | grep -q "aws_s3_bucket.*$bucket"; then
            log_warning "Orphaned S3 bucket found: $bucket"
            ((ORPHANED_COUNT++))
            
            # Get bucket size
            size=$(aws s3 ls "s3://$bucket" --recursive --summarize --human-readable --region "$AWS_REGION" 2>/dev/null | grep "Total Size" | awk '{print $3}' || echo "unknown")
            log_info "  - Bucket size: $size"
        fi
    done
}

detect_orphaned_security_groups() {
    print_section "Detecting Orphaned Security Groups"
    
    log_info "Scanning for Security Groups not managed by Terraform..."
    
    # Get all security groups
    sgs=$(aws ec2 describe-security-groups --region "$AWS_REGION" --query 'SecurityGroups[].GroupId' --output text)
    
    if [ -z "$sgs" ]; then
        log_success "No Security Groups found"
        return
    fi
    
    # Check each security group
    for sg in $sgs; do
        # Skip default security group
        if [ "$sg" = "default" ]; then
            continue
        fi
        
        # Check if SG is in Terraform state
        if ! terraform -chdir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT" state list | grep -q "aws_security_group.*$sg"; then
            log_warning "Orphaned Security Group found: $sg"
            ((ORPHANED_COUNT++))
        fi
    done
}

detect_untagged_resources() {
    print_section "Detecting Untagged Resources"
    
    log_info "Scanning for resources without proper tags..."
    
    # Check for untagged Lambda functions
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text)
    
    for function in $functions; do
        tags=$(aws lambda list-tags-by-resource --resource-arn "arn:aws:lambda:$AWS_REGION:$ACCOUNT_ID:function:$function" --query 'Tags' --output json 2>/dev/null || echo "{}")
        
        if [ "$tags" = "{}" ]; then
            log_warning "Untagged Lambda function: $function"
            ((UNTAGGED_COUNT++))
        fi
    done
    
    # Check for untagged DynamoDB tables
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text)
    
    for table in $tables; do
        table_arn=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" --query 'Table.TableArn' --output text)
        tags=$(aws dynamodb list-tags-of-resource --resource-arn "$table_arn" --query 'Tags' --output json 2>/dev/null || echo "[]")
        
        if [ "$tags" = "[]" ]; then
            log_warning "Untagged DynamoDB table: $table"
            ((UNTAGGED_COUNT++))
        fi
    done
}

estimate_costs() {
    print_section "Cost Estimation"
    
    log_info "Estimating costs for orphaned resources..."
    
    # Lambda cost estimation (rough)
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text)
    lambda_count=$(echo "$functions" | wc -w)
    lambda_cost=$(echo "scale=2; $lambda_count * 0.20" | bc)
    
    log_info "Lambda functions: $lambda_count (estimated cost: \$$lambda_cost/month)"
    
    # DynamoDB cost estimation (rough)
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text)
    dynamodb_count=$(echo "$tables" | wc -w)
    dynamodb_cost=$(echo "scale=2; $dynamodb_count * 1.00" | bc)
    
    log_info "DynamoDB tables: $dynamodb_count (estimated cost: \$$dynamodb_cost/month)"
    
    # S3 cost estimation (rough)
    buckets=$(aws s3 ls --query 'Buckets[].Name' --output text)
    s3_count=$(echo "$buckets" | wc -w)
    s3_cost=$(echo "scale=2; $s3_count * 0.50" | bc)
    
    log_info "S3 buckets: $s3_count (estimated cost: \$$s3_cost/month)"
}

generate_report() {
    print_section "Generating Report"
    
    {
        echo "Orphaned Resources Detection Report"
        echo "===================================="
        echo ""
        echo "Generated: $(date)"
        echo "Environment: $ENVIRONMENT"
        echo "AWS Account: $ACCOUNT_ID"
        echo "AWS Region: $AWS_REGION"
        echo ""
        echo "Summary:"
        echo "  Orphaned Resources: $ORPHANED_COUNT"
        echo "  Untagged Resources: $UNTAGGED_COUNT"
        echo ""
        
        if [ $ORPHANED_COUNT -eq 0 ]; then
            echo "Status: ✅ No orphaned resources detected"
        else
            echo "Status: ⚠️  Found $ORPHANED_COUNT orphaned resources"
        fi
    } | tee "$REPORT_FILE"
    
    log_success "Report saved to $REPORT_FILE"
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "Detect Orphaned Resources Script"
    
    log_info "Starting orphaned resource detection"
    log_info "Environment: $ENVIRONMENT"
    log_info "Resource Type: $RESOURCE_TYPE"
    echo ""
    
    # Check AWS credentials
    check_aws_credentials
    
    # Run detection based on resource type
    case "$RESOURCE_TYPE" in
        lambda)
            detect_orphaned_lambda_functions
            ;;
        dynamodb)
            detect_orphaned_dynamodb_tables
            ;;
        s3)
            detect_orphaned_s3_buckets
            ;;
        security-groups)
            detect_orphaned_security_groups
            ;;
        all)
            detect_orphaned_lambda_functions
            detect_orphaned_dynamodb_tables
            detect_orphaned_s3_buckets
            detect_orphaned_security_groups
            detect_untagged_resources
            ;;
        *)
            log_error "Unknown resource type: $RESOURCE_TYPE"
            echo "Valid options: lambda, dynamodb, s3, security-groups, all"
            exit 1
            ;;
    esac
    
    # Estimate costs
    estimate_costs
    
    # Generate report
    generate_report
    
    # Print summary
    print_header "Detection Summary"
    echo "Orphaned Resources: $ORPHANED_COUNT"
    echo "Untagged Resources: $UNTAGGED_COUNT"
    echo ""
    
    if [ $ORPHANED_COUNT -eq 0 ]; then
        log_success "No orphaned resources detected!"
        exit 0
    else
        log_warning "Found $ORPHANED_COUNT orphaned resources. Review the report for details."
        exit 0
    fi
}

# Run main function
main "$@"
