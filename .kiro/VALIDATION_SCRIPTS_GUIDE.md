# Infrastructure Validation Scripts Guide

## Overview

Four powerful scripts to ensure infrastructure integrity, prevent orphaned resources, and optimize costs.

---

## 1. validate-infrastructure.sh

**Purpose:** Validate Terraform configuration syntax, structure, and IAM policies

**When to use:**
- Before deploying infrastructure
- After making Terraform changes
- As part of CI/CD pipeline

**What it checks:**
- ✅ Terraform syntax validation
- ✅ Required variables are defined
- ✅ All outputs are properly configured
- ✅ All modules are properly referenced
- ✅ IAM policies follow least-privilege principle
- ✅ No hardcoded secrets or credentials

**Usage:**
```bash
cd infrastructure
./scripts/validate-infrastructure.sh
```

**Output:**
- Validation report with pass/fail status
- List of any issues found
- Recommendations for fixes

---

## 2. detect-orphaned-resources.sh

**Purpose:** Identify AWS resources not managed by Terraform

**When to use:**
- After infrastructure deployment
- Before destroying infrastructure
- Monthly cost optimization review
- When investigating unexpected AWS charges

**What it detects:**
- ✅ Untagged resources
- ✅ Resources without Terraform state
- ✅ Manually created resources
- ✅ Resources from failed deployments
- ✅ Potential cost-saving opportunities

**Usage:**
```bash
# Check all resources
./scripts/detect-orphaned-resources.sh

# Filter by resource type
./scripts/detect-orphaned-resources.sh --type lambda

# Filter by environment
./scripts/detect-orphaned-resources.sh --environment dev

# Filter by region
./scripts/detect-orphaned-resources.sh --region us-east-1
```

**Output:**
- List of orphaned resources
- Estimated monthly cost of orphaned resources
- Recommendations for cleanup
- Resource details (ID, type, creation date, tags)

---

## 3. cost-analysis.sh

**Purpose:** Estimate monthly costs and identify optimization opportunities

**When to use:**
- Monthly cost reviews
- Before scaling infrastructure
- When investigating high AWS bills
- Planning budget allocations

**What it analyzes:**
- ✅ DynamoDB on-demand vs provisioned pricing
- ✅ Lambda invocation patterns and costs
- ✅ API Gateway request costs
- ✅ CloudWatch logging costs
- ✅ S3 storage costs
- ✅ Unused resources (zero traffic, zero data)

**Usage:**
```bash
# Full cost analysis
./scripts/cost-analysis.sh

# Analyze specific service
./scripts/cost-analysis.sh --service dynamodb

# Compare pricing models
./scripts/cost-analysis.sh --compare-pricing

# Generate detailed report
./scripts/cost-analysis.sh --detailed
```

**Output:**
- Current monthly cost estimate
- Cost breakdown by service
- Pricing model comparisons
- Optimization recommendations
- Potential monthly savings

**Example Output:**
```
=== AWS Infrastructure Cost Analysis ===

Current Monthly Estimate: $145.32

Cost Breakdown:
  DynamoDB:        $45.00 (on-demand)
  Lambda:          $50.00 (1M invocations)
  API Gateway:     $35.00 (10M requests)
  CloudWatch:      $10.00 (logs)
  S3:              $5.32 (state storage)

Optimization Opportunities:
  1. Switch DynamoDB to provisioned: Save $20/month
  2. Reduce Lambda memory: Save $5/month
  3. Delete unused resources: Save $10/month

Potential Monthly Savings: $35/month
```

---

## 4. destroy-validation.sh

**Purpose:** Safely validate and prepare infrastructure for destruction

**When to use:**
- Before running `terraform destroy`
- When decommissioning environments
- Before major infrastructure changes

**What it validates:**
- ✅ No production resources are being destroyed
- ✅ Data that would be lost is identified
- ✅ Backups are created before destruction
- ✅ Terraform state is backed up
- ✅ Explicit confirmation is required

**Usage:**
```bash
# Validate before destruction
./scripts/destroy-validation.sh

# Dry-run (show what would be destroyed)
./scripts/destroy-validation.sh --dry-run

# Force destruction (use with caution)
./scripts/destroy-validation.sh --force
```

**Safety Features:**
- ✅ Prevents accidental production destruction
- ✅ Creates state backup before destruction
- ✅ Lists all resources that will be deleted
- ✅ Requires explicit confirmation
- ✅ Logs destruction for audit trail

**Output:**
- List of resources to be destroyed
- Data loss warnings
- Backup confirmation
- Destruction log

---

## Integration with GitHub Actions

These scripts are automatically integrated into the GitHub Actions workflows:

### Infrastructure Provisioning Workflow
```yaml
- name: Validate Infrastructure
  run: ./infrastructure/scripts/validate-infrastructure.sh

- name: Detect Orphaned Resources
  run: ./infrastructure/scripts/detect-orphaned-resources.sh

- name: Cost Analysis
  run: ./infrastructure/scripts/cost-analysis.sh
```

### Manual Execution
```bash
# Before deploying
./infrastructure/scripts/validate-infrastructure.sh

# After deploying
./infrastructure/scripts/detect-orphaned-resources.sh
./infrastructure/scripts/cost-analysis.sh

# Before destroying
./infrastructure/scripts/destroy-validation.sh
```

---

## Best Practices

1. **Run validation before every deployment**
   ```bash
   ./scripts/validate-infrastructure.sh
   ```

2. **Check for orphaned resources monthly**
   ```bash
   ./scripts/detect-orphaned-resources.sh
   ```

3. **Review costs quarterly**
   ```bash
   ./scripts/cost-analysis.sh --detailed
   ```

4. **Always validate before destruction**
   ```bash
   ./scripts/destroy-validation.sh
   ```

5. **Keep validation scripts updated**
   - Review scripts quarterly
   - Update for new AWS services
   - Adjust thresholds based on usage

---

## Troubleshooting

### Script not found
```bash
# Make scripts executable
chmod +x infrastructure/scripts/*.sh
```

### AWS credentials not found
```bash
# Ensure AWS credentials are configured
aws configure
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Permission denied
```bash
# Grant execute permissions
chmod +x infrastructure/scripts/validate-infrastructure.sh
```

### Script fails silently
```bash
# Run with debug output
bash -x infrastructure/scripts/validate-infrastructure.sh
```

---

## Cost Optimization Tips

Based on script recommendations:

1. **DynamoDB:** Use provisioned billing for predictable workloads
2. **Lambda:** Optimize memory allocation for cost/performance
3. **API Gateway:** Use caching to reduce request volume
4. **CloudWatch:** Set appropriate log retention periods
5. **S3:** Use lifecycle policies for old state files

---

## Monitoring & Alerts

Set up alerts for:
- Orphaned resources detected
- Cost exceeds threshold
- Validation failures
- Destruction attempts

---

## Support

For issues or questions:
1. Check script output for error messages
2. Review AWS CloudTrail for API errors
3. Verify IAM permissions
4. Check Terraform state consistency

