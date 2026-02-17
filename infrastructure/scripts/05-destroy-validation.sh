#!/bin/bash

################################################################################
# Destroy Validation Script
# 
# Purpose: Validate infrastructure safety before destruction
# Usage: ./destroy-validation.sh [environment]
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
STATE_BACKUP_DIR="$SCRIPT_DIR/state-backups"
STATE_BACKUP_FILE="$STATE_BACKUP_DIR/terraform-state-backup-$TIMESTAMP.tar.gz"

# Parameters
ENVIRONMENT="${1:-dev}"

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0
WARNINGS=0

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((VALIDATION_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((VALIDATION_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
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

check_environment() {
    print_section "Environment Validation"
    
    log_info "Checking environment: $ENVIRONMENT"
    
    # Prevent accidental production destruction
    if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "production" ]; then
        log_error "CRITICAL: Attempting to destroy PRODUCTION environment!"
        log_error "Production destruction requires explicit confirmation"
        
        read -p "Type 'destroy-prod' to confirm production destruction: " confirmation
        if [ "$confirmation" != "destroy-prod" ]; then
            log_error "Production destruction cancelled"
            exit 1
        fi
        
        log_warning "Production destruction confirmed - proceeding with caution"
    else
        log_success "Environment is not production"
    fi
}

check_terraform_state() {
    print_section "Terraform State Validation"
    
    env_dir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT"
    
    if [ ! -d "$env_dir" ]; then
        log_error "Environment directory not found: $env_dir"
        exit 1
    fi
    
    log_success "Environment directory exists"
    
    # Check for terraform state
    if [ -f "$env_dir/terraform.tfstate" ]; then
        log_success "Local Terraform state file found"
    else
        log_warning "No local Terraform state file found (using remote state)"
    fi
}

check_resources_to_destroy() {
    print_section "Resources to be Destroyed"
    
    log_info "Checking resources that will be destroyed..."
    
    env_dir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT"
    
    # Run terraform plan to see what will be destroyed
    if terraform -chdir="$env_dir" plan -destroy -out=destroy.tfplan > /dev/null 2>&1; then
        log_success "Terraform plan generated successfully"
        
        # Show what will be destroyed
        log_info "Resources to be destroyed:"
        terraform -chdir="$env_dir" show destroy.tfplan | grep "will be destroyed" || true
        
        # Clean up plan file
        rm -f "$env_dir/destroy.tfplan"
    else
        log_error "Failed to generate Terraform plan"
    fi
}

check_data_loss_risk() {
    print_section "Data Loss Risk Assessment"
    
    log_info "Checking for data that would be lost..."
    
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - cannot check for data"
        return
    fi
    
    AWS_REGION=$(aws configure get region || echo "us-east-1")
    
    # Check DynamoDB tables for data
    tables=$(aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text 2>/dev/null || echo "")
    
    for table in $tables; do
        item_count=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" --query 'Table.ItemCount' --output text 2>/dev/null || echo "0")
        
        if [ "$item_count" -gt 0 ]; then
            log_warning "DynamoDB table '$table' contains $item_count items that will be deleted"
        fi
    done
    
    # Check S3 buckets for data
    buckets=$(aws s3 ls --query 'Buckets[].Name' --output text 2>/dev/null || echo "")
    
    for bucket in $buckets; do
        object_count=$(aws s3 ls "s3://$bucket" --recursive --summarize --region "$AWS_REGION" 2>/dev/null | grep "Total Objects" | awk '{print $3}' || echo "0")
        
        if [ "$object_count" -gt 0 ]; then
            log_warning "S3 bucket '$bucket' contains $object_count objects that will be deleted"
        fi
    done
}

check_dependencies() {
    print_section "Dependency Validation"
    
    log_info "Checking for external dependencies..."
    
    # Check if any resources are referenced by external services
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not available - cannot check dependencies"
        return
    fi
    
    AWS_REGION=$(aws configure get region || echo "us-east-1")
    
    # Check for Lambda functions with event sources
    functions=$(aws lambda list-functions --region "$AWS_REGION" --query 'Functions[].FunctionName' --output text 2>/dev/null || echo "")
    
    for function in $functions; do
        event_sources=$(aws lambda list-event-source-mappings --function-name "$function" --region "$AWS_REGION" --query 'EventSourceMappings' --output json 2>/dev/null || echo "[]")
        
        if [ "$event_sources" != "[]" ]; then
            log_warning "Lambda function '$function' has event source mappings"
        fi
    done
}

backup_terraform_state() {
    print_section "Terraform State Backup"
    
    log_info "Creating backup of Terraform state..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$STATE_BACKUP_DIR"
    
    env_dir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT"
    
    # Backup local state if it exists
    if [ -f "$env_dir/terraform.tfstate" ]; then
        tar -czf "$STATE_BACKUP_FILE" -C "$env_dir" terraform.tfstate terraform.tfstate.backup 2>/dev/null || true
        log_success "Terraform state backed up to $STATE_BACKUP_FILE"
    else
        log_info "No local state file to backup (using remote state)"
    fi
}

print_summary() {
    print_section "Validation Summary"
    
    echo "Passed: $VALIDATION_PASSED"
    echo "Failed: $VALIDATION_FAILED"
    echo "Warnings: $WARNINGS"
    echo ""
    
    if [ $VALIDATION_FAILED -gt 0 ]; then
        log_error "Validation failed - destruction cancelled"
        exit 1
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        log_warning "Validation passed with $WARNINGS warnings"
        log_warning "Please review the warnings above before proceeding"
    else
        log_success "All validations passed"
    fi
}

confirm_destruction() {
    print_section "Destruction Confirmation"
    
    log_warning "This action will destroy all infrastructure in the '$ENVIRONMENT' environment"
    log_warning "This action cannot be undone"
    echo ""
    
    read -p "Type 'destroy-$ENVIRONMENT' to confirm destruction: " confirmation
    
    if [ "$confirmation" != "destroy-$ENVIRONMENT" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    log_warning "Destruction confirmed - proceeding with terraform destroy"
    
    # Run terraform destroy
    env_dir="$INFRASTRUCTURE_DIR/environments/$ENVIRONMENT"
    
    if terraform -chdir="$env_dir" destroy -auto-approve; then
        log_success "Infrastructure destroyed successfully"
    else
        log_error "Terraform destroy failed"
        exit 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "Destroy Validation Script"
    
    log_info "Starting destruction validation for environment: $ENVIRONMENT"
    echo ""
    
    # Run validations
    check_environment
    check_terraform_state
    check_resources_to_destroy
    check_data_loss_risk
    check_dependencies
    backup_terraform_state
    
    # Print summary
    print_summary
    
    # Ask for confirmation
    read -p "Do you want to proceed with destruction? (yes/no): " proceed
    
    if [ "$proceed" = "yes" ]; then
        confirm_destruction
    else
        log_info "Destruction cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
