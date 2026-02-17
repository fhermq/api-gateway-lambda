# DynamoDB Module - Items Table

This module creates a DynamoDB table for storing application items with support for both on-demand and provisioned billing modes.

## 📋 Resources Created

### DynamoDB Table - Items
- **Table Name**: `{project_name}-items-{environment}`
- **Partition Key**: `id` (String)
- **Billing Mode**: On-demand (PAY_PER_REQUEST) or Provisioned
- **Stream**: Enabled with NEW_AND_OLD_IMAGES view type

### Attributes
- `id` (String) - Unique item identifier
- `status` (String) - Item status (used in GSI)
- `createdAt` (Number) - Unix timestamp of creation (used in GSI)

### Global Secondary Index - status-index
- **Partition Key**: `status`
- **Sort Key**: `createdAt`
- **Projection**: ALL (all attributes)
- **Purpose**: Query items by status and creation time

### Features
✅ **Point-in-Time Recovery** - Enabled for data protection  
✅ **Server-Side Encryption** - AWS managed or customer managed KMS  
✅ **TTL Support** - Automatic item expiration via `expiresAt` attribute  
✅ **Streams** - Capture item changes for event processing  
✅ **Autoscaling** - Automatic capacity adjustment (provisioned mode)  
✅ **Tags** - Environment and project tracking  

## 📝 Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | - | Environment name (dev, staging, prod) |
| `project_name` | string | - | Project name for resource naming |
| `dynamodb_billing_mode` | string | PAY_PER_REQUEST | Billing mode (PAY_PER_REQUEST or PROVISIONED) |
| `table_read_capacity` | number | 5 | Table read capacity (provisioned mode) |
| `table_write_capacity` | number | 5 | Table write capacity (provisioned mode) |
| `table_max_read_capacity` | number | 40000 | Max read capacity for autoscaling |
| `table_max_write_capacity` | number | 40000 | Max write capacity for autoscaling |
| `gsi_read_capacity` | number | 5 | GSI read capacity (provisioned mode) |
| `gsi_write_capacity` | number | 5 | GSI write capacity (provisioned mode) |
| `gsi_max_read_capacity` | number | 40000 | Max GSI read capacity for autoscaling |
| `gsi_max_write_capacity` | number | 40000 | Max GSI write capacity for autoscaling |
| `kms_key_arn` | string | null | KMS key ARN for encryption (optional) |
| `tags` | map(string) | {} | Additional tags |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `table_name` | Name of the items table |
| `table_arn` | ARN of the items table |
| `table_id` | ID of the items table |
| `table_stream_arn` | ARN of the DynamoDB stream |
| `table_stream_label` | Label of the DynamoDB stream |
| `gsi_name` | Name of the status-index GSI |
| `table_region` | AWS region |
| `table_account_id` | AWS account ID |

## 🚀 Usage

### On-Demand Billing (Recommended for MVP)

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"
  
  environment              = var.environment
  project_name             = var.project_name
  dynamodb_billing_mode    = "PAY_PER_REQUEST"
  tags                     = var.tags
}
```

### Provisioned Billing with Autoscaling

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"
  
  environment              = var.environment
  project_name             = var.project_name
  dynamodb_billing_mode    = "PROVISIONED"
  table_read_capacity      = 10
  table_write_capacity     = 10
  table_max_read_capacity  = 40000
  table_max_write_capacity = 40000
  tags                     = var.tags
}
```

## 📊 Table Schema

### Items Table Structure

```
Partition Key: id (String)
  - Unique identifier for each item
  - Example: "550e8400-e29b-41d4-a716-446655440000"

Attributes:
  - id: String (Partition Key)
  - name: String (Item name)
  - description: String (Item description)
  - status: String (Item status: active, inactive, archived)
  - createdAt: Number (Unix timestamp)
  - updatedAt: Number (Unix timestamp)
  - createdBy: String (User ID who created)
  - version: Number (Item version for optimistic locking)
  - expiresAt: Number (Unix timestamp for TTL)

Global Secondary Index: status-index
  - Partition Key: status
  - Sort Key: createdAt
  - Use Case: Query items by status, sorted by creation time
  - Example Query: Get all active items created in last 7 days
```

## 🔐 Security Features

✅ **Encryption at Rest** - AWS managed or customer managed KMS  
✅ **Point-in-Time Recovery** - Restore to any point in time  
✅ **Streams** - Capture changes for audit logging  
✅ **IAM Integration** - Fine-grained access control via IAM roles  
✅ **VPC Endpoints** - Private connectivity (optional)  

## 💰 Cost Optimization

### On-Demand Mode (PAY_PER_REQUEST)
- **Best for**: Unpredictable workloads, development, testing
- **Pricing**: Per request (read/write)
- **Autoscaling**: Automatic, no configuration needed
- **Minimum Cost**: ~$0.25/month (minimal usage)

### Provisioned Mode
- **Best for**: Predictable workloads, production
- **Pricing**: Per capacity unit per hour
- **Autoscaling**: Manual configuration with target tracking
- **Minimum Cost**: ~$1.25/month (1 RCU + 1 WCU)

### Cost Estimation

**On-Demand (Dev Environment)**:
- 1M reads/month: ~$0.25
- 1M writes/month: ~$1.25
- Storage: ~$0.25/GB

**Provisioned (Prod Environment)**:
- 100 RCU: ~$47.50/month
- 100 WCU: ~$47.50/month
- Storage: ~$0.25/GB

## 🆘 Troubleshooting

### Table Creation Fails

**Cause**: Billing mode or capacity validation error

**Solution**:
1. Check billing mode is valid (PAY_PER_REQUEST or PROVISIONED)
2. Verify capacity units are within valid range (1-40000)
3. Check IAM permissions for DynamoDB

### High Costs

**Cause**: Inefficient queries or excessive capacity

**Solution**:
1. Review query patterns and add GSIs if needed
2. Enable autoscaling for provisioned mode
3. Consider switching to on-demand for variable workloads
4. Review CloudWatch metrics for usage patterns

### Slow Queries

**Cause**: Insufficient capacity or missing indexes

**Solution**:
1. Check CloudWatch metrics for throttling
2. Add GSI for common query patterns
3. Increase capacity or enable autoscaling
4. Review query design and use batch operations

## 📞 Support

For issues:
1. Check CloudWatch metrics for table health
2. Review CloudTrail for API errors
3. Verify IAM permissions
4. Check DynamoDB Streams for change capture
