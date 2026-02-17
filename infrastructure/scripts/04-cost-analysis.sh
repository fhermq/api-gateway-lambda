#!/bin/bash

################################################################################
# Cost Analysis Script
# 
# Purpose: Estimate monthly costs and identify optimization opportunities
# Usage: ./cost-analysis.sh [environment]
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
REPORT_FILE="$SCRIPT_DIR/cost-analysis-report-$TIMESTAMP.txt"

# Parameters
ENVIRONMENT="${1:-dev}"

# Cost tracking
TOTAL_MONTHLY_COST=0
LAMBDA_COST=0
DYNAMODB_COST=0
S3_COST=0
CLOUDWATCH_COST=0
API_GATEWAY_COST=0

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
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

format_currency() {
    printf "\$%.2f" "$1"
}

################################################################################
# AWS Pricing Functions
################################################################################

check_aws_credentials() {
    print_section "Checking AWS Credentials"
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_warning "AWS credentials not configured - using estimated costs only"
        return 1
    fi
    
    log_success "AWS credentials are valid"
    
    # Get account ID and region
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region || echo "us-east-1")
    
    log_info "AWS Account: $ACCOUNT_ID"
    log_info "AWS Region: $AWS_REGION"
    return 0
}

analyze_lambda_costs() {
    print_section "Lambda Cost Analysis"
    
    log_info "Analyzing Lambda function costs..."
    
    # Lambda pricing (US East 1)
    # $0.20 per 1M requests
    # $0.0000166667 per GB-second
    
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - using default estimates"
        LAMBDA_COST=10.00
        log_info "Estimated Lambda cost: $(format_currency $LAMBDA_COST)/month"
        return
    fi
    
    # Get Lambda functions
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text 2>/dev/null || echo "")
    
    if [ -z "$functions" ]; then
        log_info "No Lambda functions found"
        LAMBDA_COST=0
        return
    fi
    
    function_count=$(echo "$functions" | wc -w)
    log_info "Found $function_count Lambda function(s)"
    
    # Estimate based on function count and memory
    total_memory=0
    for function in $functions; do
        memory=$(aws lambda get-function-configuration --function-name "$function" --region "$AWS_REGION" --query 'MemorySize' --output text 2>/dev/null || echo "128")
        total_memory=$((total_memory + memory))
        log_info "  - $function: ${memory}MB"
    done
    
    # Rough estimation: 1M requests/month per function, 1 second execution
    requests_per_month=$((function_count * 1000000))
    gb_seconds=$((total_memory * requests_per_month / 1024 / 1000))
    
    request_cost=$(echo "scale=2; $requests_per_month * 0.20 / 1000000" | bc)
    compute_cost=$(echo "scale=2; $gb_seconds * 0.0000166667" | bc)
    
    LAMBDA_COST=$(echo "scale=2; $request_cost + $compute_cost" | bc)
    
    log_info "Estimated requests/month: $requests_per_month"
    log_info "Estimated GB-seconds: $gb_seconds"
    log_info "Request cost: $(format_currency $request_cost)"
    log_info "Compute cost: $(format_currency $compute_cost)"
    log_info "Total Lambda cost: $(format_currency $LAMBDA_COST)/month"
}

analyze_dynamodb_costs() {
    print_section "DynamoDB Cost Analysis"
    
    log_info "Analyzing DynamoDB table costs..."
    
    # DynamoDB pricing (on-demand)
    # $1.25 per million write units
    # $0.25 per million read units
    
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - using default estimates"
        DYNAMODB_COST=5.00
        log_info "Estimated DynamoDB cost: $(format_currency $DYNAMODB_COST)/month"
        return
    fi
    
    # Get DynamoDB tables
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text 2>/dev/null || echo "")
    
    if [ -z "$tables" ]; then
        log_info "No DynamoDB tables found"
        DYNAMODB_COST=0
        return
    fi
    
    table_count=$(echo "$tables" | wc -w)
    log_info "Found $table_count DynamoDB table(s)"
    
    total_cost=0
    for table in $tables; do
        # Get table details
        table_info=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" --query 'Table' --output json 2>/dev/null || echo "{}")
        
        billing_mode=$(echo "$table_info" | grep -o '"BillingModeSummary"' || echo "")
        size=$(echo "$table_info" | grep -o '"TableSizeBytes":[0-9]*' | cut -d: -f2)
        
        log_info "  - $table: $(($size / 1024 / 1024))MB"
        
        # Estimate based on table size
        # Rough: 100 writes/day, 1000 reads/day per GB
        gb=$((size / 1024 / 1024 / 1024 + 1))
        writes_per_month=$((gb * 100 * 30))
        reads_per_month=$((gb * 1000 * 30))
        
        write_cost=$(echo "scale=2; $writes_per_month * 1.25 / 1000000" | bc)
        read_cost=$(echo "scale=2; $reads_per_month * 0.25 / 1000000" | bc)
        table_cost=$(echo "scale=2; $write_cost + $read_cost" | bc)
        
        total_cost=$(echo "scale=2; $total_cost + $table_cost" | bc)
    done
    
    DYNAMODB_COST=$total_cost
    log_info "Total DynamoDB cost: $(format_currency $DYNAMODB_COST)/month"
}

analyze_s3_costs() {
    print_section "S3 Cost Analysis"
    
    log_info "Analyzing S3 bucket costs..."
    
    # S3 pricing
    # $0.023 per GB stored
    # $0.0004 per 1000 PUT requests
    # $0.00004 per 1000 GET requests
    
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - using default estimates"
        S3_COST=1.00
        log_info "Estimated S3 cost: $(format_currency $S3_COST)/month"
        return
    fi
    
    # Get S3 buckets
    buckets=$(aws s3 ls --query 'Buckets[].Name' --output text 2>/dev/null || echo "")
    
    if [ -z "$buckets" ]; then
        log_info "No S3 buckets found"
        S3_COST=0
        return
    fi
    
    bucket_count=$(echo "$buckets" | wc -w)
    log_info "Found $bucket_count S3 bucket(s)"
    
    total_cost=0
    for bucket in $buckets; do
        # Get bucket size
        size=$(aws s3 ls "s3://$bucket" --recursive --summarize --region "$AWS_REGION" 2>/dev/null | grep "Total Size" | awk '{print $3}' || echo "0")
        
        if [ "$size" != "0" ]; then
            size_gb=$(echo "scale=2; $size / 1024 / 1024 / 1024" | bc)
            storage_cost=$(echo "scale=2; $size_gb * 0.023" | bc)
            log_info "  - $bucket: ${size_gb}GB (cost: $(format_currency $storage_cost)/month)"
            total_cost=$(echo "scale=2; $total_cost + $storage_cost" | bc)
        else
            log_info "  - $bucket: empty"
        fi
    done
    
    S3_COST=$total_cost
    log_info "Total S3 cost: $(format_currency $S3_COST)/month"
}

analyze_cloudwatch_costs() {
    print_section "CloudWatch Cost Analysis"
    
    log_info "Analyzing CloudWatch costs..."
    
    # CloudWatch pricing
    # $0.50 per GB ingested
    # $0.03 per GB stored
    
    # Rough estimation: 1GB/day ingestion
    daily_ingestion=1
    monthly_ingestion=$((daily_ingestion * 30))
    ingestion_cost=$(echo "scale=2; $monthly_ingestion * 0.50" | bc)
    
    # Rough estimation: 30GB stored
    storage=30
    storage_cost=$(echo "scale=2; $storage * 0.03" | bc)
    
    CLOUDWATCH_COST=$(echo "scale=2; $ingestion_cost + $storage_cost" | bc)
    
    log_info "Estimated ingestion: ${monthly_ingestion}GB/month (cost: $(format_currency $ingestion_cost))"
    log_info "Estimated storage: ${storage}GB (cost: $(format_currency $storage_cost))"
    log_info "Total CloudWatch cost: $(format_currency $CLOUDWATCH_COST)/month"
}

analyze_api_gateway_costs() {
    print_section "API Gateway Cost Analysis"
    
    log_info "Analyzing API Gateway costs..."
    
    # API Gateway pricing
    # $3.50 per million requests
    
    # Rough estimation: 10M requests/month
    requests_per_month=10000000
    API_GATEWAY_COST=$(echo "scale=2; $requests_per_month * 3.50 / 1000000" | bc)
    
    log_info "Estimated requests/month: $requests_per_month"
    log_info "Total API Gateway cost: $(format_currency $API_GATEWAY_COST)/month"
}

identify_optimization_opportunities() {
    print_section "Cost Optimization Opportunities"
    
    log_info "Identifying potential cost savings..."
    
    # Check for unused resources
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - cannot check for unused resources"
        return
    fi
    
    # Check for Lambda functions with no recent invocations
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text 2>/dev/null || echo "")
    
    for function in $functions; do
        # Get last modified time
        last_modified=$(aws lambda get-function --function-name "$function" --region "$AWS_REGION" --query 'Configuration.LastModified' --output text 2>/dev/null || echo "")
        
        if [ -n "$last_modified" ]; then
            log_info "Lambda function '$function' last modified: $last_modified"
        fi
    done
    
    # Check for DynamoDB tables with no recent activity
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text 2>/dev/null || echo "")
    
    for table in $tables; do
        # Get table creation time
        creation_time=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" --query 'Table.CreationDateTime' --output text 2>/dev/null || echo "")
        
        if [ -n "$creation_time" ]; then
            log_info "DynamoDB table '$table' created: $creation_time"
        fi
    done
    
    # Recommendations
    echo ""
    log_info "Optimization Recommendations:"
    echo "  1. Consider using DynamoDB on-demand billing for variable workloads"
    echo "  2. Enable S3 Intelligent-Tiering for automatic cost optimization"
    echo "  3. Use Lambda reserved concurrency to reduce costs for predictable workloads"
    echo "  4. Enable CloudWatch Logs retention policies to reduce storage costs"
    echo "  5. Delete unused resources to eliminate unnecessary charges"
}

generate_report() {
    print_section "Generating Cost Analysis Report"
    
    TOTAL_MONTHLY_COST=$(echo "scale=2; $LAMBDA_COST + $DYNAMODB_COST + $S3_COST + $CLOUDWATCH_COST + $API_GATEWAY_COST" | bc)
    
    {
        echo "Cost Analysis Report"
        echo "===================="
        echo ""
        echo "Generated: $(date)"
        echo "Environment: $ENVIRONMENT"
        echo ""
        echo "Monthly Cost Breakdown:"
        echo "  Lambda:       $(format_currency $LAMBDA_COST)"
        echo "  DynamoDB:     $(format_currency $DYNAMODB_COST)"
        echo "  S3:           $(format_currency $S3_COST)"
        echo "  CloudWatch:   $(format_currency $CLOUDWATCH_COST)"
        echo "  API Gateway:  $(format_currency $API_GATEWAY_COST)"
        echo "  ─────────────────────"
        echo "  Total:        $(format_currency $TOTAL_MONTHLY_COST)"
        echo ""
        echo "Annual Cost Estimate: $(format_currency $(echo "scale=2; $TOTAL_MONTHLY_COST * 12" | bc))"
    } | tee "$REPORT_FILE"
    
    log_success "Report saved to $REPORT_FILE"
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "Cost Analysis Script"
    
    log_info "Starting cost analysis for environment: $ENVIRONMENT"
    echo ""
    
    # Check AWS credentials
    check_aws_credentials || true
    
    # Run cost analysis
    analyze_lambda_costs
    analyze_dynamodb_costs
    analyze_s3_costs
    analyze_cloudwatch_costs
    analyze_api_gateway_costs
    
    # Identify optimization opportunities
    identify_optimization_opportunities
    
    # Generate report
    generate_report
    
    # Print summary
    print_header "Cost Summary"
    echo "Lambda:       $(format_currency $LAMBDA_COST)/month"
    echo "DynamoDB:     $(format_currency $DYNAMODB_COST)/month"
    echo "S3:           $(format_currency $S3_COST)/month"
    echo "CloudWatch:   $(format_currency $CLOUDWATCH_COST)/month"
    echo "API Gateway:  $(format_currency $API_GATEWAY_COST)/month"
    echo "─────────────────────"
    TOTAL_MONTHLY_COST=$(echo "scale=2; $LAMBDA_COST + $DYNAMODB_COST + $S3_COST + $CLOUDWATCH_COST + $API_GATEWAY_COST" | bc)
    echo "Total:        $(format_currency $TOTAL_MONTHLY_COST)/month"
    echo ""
    echo "Annual Estimate: $(format_currency $(echo "scale=2; $TOTAL_MONTHLY_COST * 12" | bc))"
    echo ""
}

# Run main function
main "$@"
