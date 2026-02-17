#!/bin/bash

# Destroy Environment Script
# This script safely destroys an entire environment including all S3 buckets
# Usage: ./07-destroy-environment.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Environment Destruction Script"
echo "========================================"
echo ""
echo "⚠️  WARNING: This will destroy all infrastructure for: $ENVIRONMENT"
echo ""
read -p "Are you sure? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

echo ""
echo "--- Step 1: Validate Destruction Safety ---"
bash "$SCRIPT_DIR/05-destroy-validation.sh" "$ENVIRONMENT"

echo ""
echo "--- Step 2: Terraform Destroy ---"
cd "infrastructure/environments/$ENVIRONMENT"
terraform destroy -auto-approve -lock=false || true
cd - > /dev/null

echo ""
echo "--- Step 3: Cleanup S3 Buckets ---"
bash "$SCRIPT_DIR/06-cleanup-s3-buckets.sh" "$ENVIRONMENT"

echo ""
echo "--- Step 4: Verify Cleanup ---"
bash "$SCRIPT_DIR/03-detect-orphaned-resources.sh" "$ENVIRONMENT" all

echo ""
echo "========================================"
echo "✅ Environment Destruction Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Review the orphaned resources report"
echo "2. Manually delete any remaining resources if needed"
echo "3. Verify in AWS Console that all resources are gone"
