# S3 Module - Reusable S3 bucket configurations
# Used for Lambda code storage and other application needs

# S3 Bucket for Lambda Code Deployments
resource "aws_s3_bucket" "lambda_code" {
  bucket = "${var.project_name}-lambda-code-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-lambda-code"
      Environment = var.environment
      Purpose     = "Lambda function code storage"
    }
  )
}

# Enable versioning on Lambda code bucket
resource "aws_s3_bucket_versioning" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy to clean up old versions and delete markers
resource "aws_s3_bucket_lifecycle_configuration" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    # Remove delete markers for deleted objects
    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Enable server-side encryption on Lambda code bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to Lambda code bucket
resource "aws_s3_bucket_public_access_block" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging for Lambda code bucket
resource "aws_s3_bucket_logging" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  target_bucket = aws_s3_bucket.lambda_code_logs.id
  target_prefix = "lambda-code-logs/"
}

# S3 Bucket for Lambda Code Access Logs
resource "aws_s3_bucket" "lambda_code_logs" {
  bucket = "${var.project_name}-lambda-code-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-lambda-code-logs"
      Environment = var.environment
      Purpose     = "Lambda code bucket access logs"
    }
  )
}

# Block public access to logs bucket
resource "aws_s3_bucket_public_access_block" "lambda_code_logs" {
  bucket = aws_s3_bucket.lambda_code_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on logs bucket
resource "aws_s3_bucket_versioning" "lambda_code_logs" {
  bucket = aws_s3_bucket.lambda_code_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for logs bucket - delete old logs after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "lambda_code_logs" {
  bucket = aws_s3_bucket.lambda_code_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
