# S3 Bucket Cleanup Fixes

## Problem

Terraform `destroy` command could not delete S3 buckets because:
1. S3 buckets had versioning enabled
2. Buckets contained multiple versions of objects
3. Buckets contained delete markers
4. Terraform cannot delete non-empty buckets

This resulted in orphaned S3 buckets after infrastructure destruction.

## Solution

### 1. Lifecycle Policies (Automatic Cleanup)

Added lifecycle policies to all S3 buckets to automatically clean up old versions:

**Lambda Code Buckets** (`infrastructure/modules/s3/main.tf`):
- Delete old object versions after 7 days
- Remove expired delete markers
- Reduces storage costs

**Terraform State Buckets** (`infrastructure/global/main.tf`):
- Delete old state versions after 7 days
- Delete logs older than 30 days
- Remove expired delete markers

**Benefits:**
- Automatic cleanup prevents version accumulation
- Reduces S3 storage costs
- Enables easier bucket deletion
- Complies with retention policies

### 2. Cleanup Scripts

Created two new scripts to handle manual cleanup:

**06-cleanup-s3-buckets.sh** - Safely delete versioned S3 buckets:
```bash
./infrastructure/scripts/06-cleanup-s3-buckets.sh [environment]
```

**07-destroy-environment.sh** - Complete destruction workflow:
```bash
./infrastructure/scripts/07-destroy-environment.sh [environment]
```

### 3. Updated Environments

Applied fixes to all three environments:
- ✅ Development (dev)
- ✅ Staging (staging)
- ✅ Production (prod)

## Files Modified

### Infrastructure Modules
- `infrastructure/modules/s3/main.tf` - Added lifecycle policies to Lambda buckets
- `infrastructure/global/main.tf` - Added lifecycle policies to Terraform state buckets

### Scripts
- `infrastructure/scripts/06-cleanup-s3-buckets.sh` - New cleanup script
- `infrastructure/scripts/07-destroy-environment.sh` - New destruction workflow script
- `infrastructure/scripts/README.md` - Updated documentation

## Usage

### Automatic Cleanup (Recommended)

Lifecycle policies automatically clean up old versions:
- Old versions deleted after 7 days
- Delete markers removed automatically
- No manual intervention needed

### Manual Cleanup (If Needed)

For immediate cleanup:

```bash
# Clean up S3 buckets for an environment
./infrastructure/scripts/06-cleanup-s3-buckets.sh dev

# Complete destruction with cleanup
./infrastructure/scripts/07-destroy-environment.sh dev
```

## Complete Destruction Workflow

```bash
# Step 1: Validate safety
./infrastructure/scripts/05-destroy-validation.sh dev

# Step 2: Run complete destruction
./infrastructure/scripts/07-destroy-environment.sh dev

# Step 3: Verify cleanup
./infrastructure/scripts/03-detect-orphaned-resources.sh dev all
```

## Lifecycle Policy Details

### Lambda Code Buckets
```hcl
rule {
  id     = "delete-old-versions"
  status = "Enabled"

  noncurrent_version_expiration {
    noncurrent_days = 7
  }

  expiration {
    expired_object_delete_marker = true
  }
}
```

### Terraform State Buckets
```hcl
rule {
  id     = "delete-old-state-versions"
  status = "Enabled"

  noncurrent_version_expiration {
    noncurrent_days = 7
  }

  expiration {
    expired_object_delete_marker = true
  }
}
```

### Terraform Logs Buckets
```hcl
rule {
  id     = "delete-old-logs"
  status = "Enabled"

  expiration {
    days = 30
  }

  noncurrent_version_expiration {
    noncurrent_days = 7
  }

  expiration {
    expired_object_delete_marker = true
  }
}
```

## Benefits

1. **Automatic Cleanup**: Old versions automatically deleted after 7 days
2. **Cost Reduction**: Fewer stored versions = lower S3 costs
3. **Easier Destruction**: Buckets can be deleted without manual cleanup
4. **Compliance**: Retention policies enforced automatically
5. **Reliability**: Prevents orphaned resources

## Testing

To test the cleanup process:

```bash
# Deploy infrastructure
terraform -chdir="infrastructure/environments/dev" apply -auto-approve

# Wait for lifecycle policy to take effect (or manually trigger)
# Then destroy
terraform -chdir="infrastructure/environments/dev" destroy -auto-approve

# Verify cleanup
./infrastructure/scripts/03-detect-orphaned-resources.sh dev all
```

## Future Improvements

1. **Automated Destruction**: Add GitHub Actions workflow for safe destruction
2. **Cost Alerts**: Alert when S3 costs exceed threshold
3. **Backup Retention**: Implement backup retention policies
4. **Audit Logging**: Enhanced logging for all destruction operations
5. **Dry-Run Mode**: Add dry-run option to preview what will be destroyed

## References

- [AWS S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Terraform S3 Bucket Lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)
- [AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
