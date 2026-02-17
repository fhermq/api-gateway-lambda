#!/bin/bash

# Cleanup S3 Buckets Script
# This script safely deletes S3 buckets that may have versioning enabled
# Usage: ./06-cleanup-s3-buckets.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-us-east-1}

echo "========================================"
echo "S3 Bucket Cleanup Script"
echo "========================================"
echo ""
echo "ℹ️  Environment: $ENVIRONMENT"
echo "ℹ️  Account ID: $ACCOUNT_ID"
echo "ℹ️  Region: $REGION"
echo ""

# Function to delete all versions of objects in a bucket
delete_bucket_versions() {
    local bucket=$1
    
    echo "ℹ️  Deleting all versions from bucket: $bucket"
    
    # Delete all object versions
    aws s3api list-object-versions \
        --bucket "$bucket" \
        --query 'Versions[*].[Key,VersionId]' \
        --output text | \
    while read key version; do
        if [ -n "$key" ] && [ -n "$version" ]; then
            aws s3api delete-object \
                --bucket "$bucket" \
                --key "$key" \
                --version-id "$version" > /dev/null
            echo "  ✓ Deleted $key (version: $version)"
        fi
    done
    
    # Delete all delete markers
    aws s3api list-object-versions \
        --bucket "$bucket" \
        --query 'DeleteMarkers[*].[Key,VersionId]' \
        --output text | \
    while read key version; do
        if [ -n "$key" ]; then
            aws s3api delete-object \
                --bucket "$bucket" \
                --key "$key" \
                --version-id "$version" > /dev/null
            echo "  ✓ Deleted marker for $key"
        fi
    done
}

# Function to delete a bucket
delete_bucket() {
    local bucket=$1
    
    echo "ℹ️  Deleting bucket: $bucket"
    
    # Check if bucket exists
    if ! aws s3 ls "s3://$bucket" 2>/dev/null; then
        echo "⚠️  Bucket does not exist: $bucket"
        return 0
    fi
    
    # Delete all versions
    delete_bucket_versions "$bucket"
    
    # Delete the bucket
    if aws s3api delete-bucket --bucket "$bucket" 2>/dev/null; then
        echo "✅ Bucket deleted: $bucket"
    else
        echo "❌ Failed to delete bucket: $bucket"
        return 1
    fi
}

# Delete Lambda code buckets
echo "--- Deleting Lambda Code Buckets ---"
delete_bucket "serverless-monorepo-lambda-code-${ENVIRONMENT}-${ACCOUNT_ID}" || true
delete_bucket "serverless-monorepo-lambda-code-logs-${ENVIRONMENT}-${ACCOUNT_ID}" || true

# Delete Terraform state buckets (only for global cleanup)
if [ "$ENVIRONMENT" = "global" ] || [ "$ENVIRONMENT" = "all" ]; then
    echo ""
    echo "--- Deleting Terraform State Buckets ---"
    delete_bucket "terraform-state-${ACCOUNT_ID}-${REGION}" || true
    delete_bucket "terraform-state-logs-${ACCOUNT_ID}-${REGION}" || true
fi

echo ""
echo "========================================"
echo "✅ S3 Bucket Cleanup Complete"
echo "========================================"
