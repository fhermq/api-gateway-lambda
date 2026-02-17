# DynamoDB Module - Items Table for Serverless Application

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# ============================================================================
# DynamoDB Table - Items
# ============================================================================

resource "aws_dynamodb_table" "items" {
  name             = "${var.project_name}-items-${var.environment}"
  billing_mode     = var.dynamodb_billing_mode
  hash_key         = "id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Attributes
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  # Global Secondary Index - Query by status and createdAt
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # TTL for automatic item expiration
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-items-${var.environment}"
      Environment = var.environment
      Purpose     = "Application Items Storage"
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# DynamoDB Table Point-in-Time Recovery
# ============================================================================

# Point-in-time recovery and encryption are enabled via table attributes
# See aws_dynamodb_table resource above

# ============================================================================
# DynamoDB Table Autoscaling (if using provisioned mode)
# ============================================================================

# Autoscaling for table read capacity
resource "aws_appautoscaling_target" "dynamodb_table_read" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.table_max_read_capacity
  min_capacity       = var.table_read_capacity
  resource_id        = "table/${aws_dynamodb_table.items.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${aws_dynamodb_table.items.name}-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}

# Autoscaling for table write capacity
resource "aws_appautoscaling_target" "dynamodb_table_write" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.table_max_write_capacity
  min_capacity       = var.table_write_capacity
  resource_id        = "table/${aws_dynamodb_table.items.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_write" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${aws_dynamodb_table.items.name}-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}

# Autoscaling for GSI read capacity
resource "aws_appautoscaling_target" "dynamodb_gsi_read" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.gsi_max_read_capacity
  min_capacity       = var.gsi_read_capacity
  resource_id        = "table/${aws_dynamodb_table.items.name}/index/status-index"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_gsi_read" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${aws_dynamodb_table.items.name}-gsi-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_gsi_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_gsi_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_gsi_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}

# Autoscaling for GSI write capacity
resource "aws_appautoscaling_target" "dynamodb_gsi_write" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.gsi_max_write_capacity
  min_capacity       = var.gsi_write_capacity
  resource_id        = "table/${aws_dynamodb_table.items.name}/index/status-index"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_gsi_write" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${aws_dynamodb_table.items.name}-gsi-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_gsi_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_gsi_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_gsi_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}
