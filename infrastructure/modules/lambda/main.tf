# Lambda Module - API Handler Function for CRUD Operations

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# ============================================================================
# CloudWatch Log Group for Lambda
# ============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-api-handler-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-lambda-logs-${var.environment}"
      Environment = var.environment
      Purpose     = "Lambda Function Logs"
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# Lambda Function - API Handler
# ============================================================================

resource "aws_lambda_function" "api_handler" {
  filename         = var.lambda_code_path
  function_name    = "${var.project_name}-api-handler-${var.environment}"
  role             = var.lambda_execution_role_arn
  handler          = var.lambda_handler
  source_code_hash = filebase64sha256(var.lambda_code_path)
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  # Environment variables
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      ENVIRONMENT         = var.environment
      PROJECT_NAME        = var.project_name
      LOG_LEVEL           = var.log_level
    }
  }

  # CloudWatch Logs configuration
  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda.name
    log_format = "JSON"
  }

  # VPC configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # Tracing configuration (optional)
  dynamic "tracing_config" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      mode = "Active"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-handler-${var.environment}"
      Environment = var.environment
      Purpose     = "CRUD Operations Handler"
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_cloudwatch_log_group.lambda]
}

# ============================================================================
# Lambda Function Alias (Optional - for versioning)
# ============================================================================

resource "aws_lambda_alias" "api_handler_live" {
  count             = var.create_alias ? 1 : 0
  name              = "live"
  description       = "Live alias for ${var.project_name}-api-handler"
  function_name     = aws_lambda_function.api_handler.function_name
  function_version  = aws_lambda_function.api_handler.version
}

# ============================================================================
# Lambda Function Concurrency Limit (Optional)
# ============================================================================

resource "aws_lambda_provisioned_concurrency_config" "api_handler" {
  count                             = var.reserved_concurrent_executions > 0 ? 1 : 0
  function_name                     = aws_lambda_function.api_handler.function_name
  provisioned_concurrent_executions = var.reserved_concurrent_executions
  qualifier                         = aws_lambda_function.api_handler.version
}

# ============================================================================
# CloudWatch Alarms for Lambda (Optional)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-api-handler-errors-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Lambda function errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.api_handler.function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-handler-errors-alarm-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-api-handler-throttles-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when Lambda function is throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.api_handler.function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-handler-throttles-alarm-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-api-handler-duration-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.lambda_timeout * 1000 * 0.8  # 80% of timeout
  alarm_description   = "Alert when Lambda function duration is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.api_handler.function_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-handler-duration-alarm-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
