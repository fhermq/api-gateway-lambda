# DynamoDB Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "table_read_capacity" {
  description = "DynamoDB table read capacity units (for provisioned mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.table_read_capacity >= 1 && var.table_read_capacity <= 40000
    error_message = "Read capacity must be between 1 and 40000."
  }
}

variable "table_write_capacity" {
  description = "DynamoDB table write capacity units (for provisioned mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.table_write_capacity >= 1 && var.table_write_capacity <= 40000
    error_message = "Write capacity must be between 1 and 40000."
  }
}

variable "table_max_read_capacity" {
  description = "Maximum read capacity for autoscaling"
  type        = number
  default     = 40000
}

variable "table_max_write_capacity" {
  description = "Maximum write capacity for autoscaling"
  type        = number
  default     = 40000
}

variable "gsi_read_capacity" {
  description = "GSI read capacity units (for provisioned mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.gsi_read_capacity >= 1 && var.gsi_read_capacity <= 40000
    error_message = "GSI read capacity must be between 1 and 40000."
  }
}

variable "gsi_write_capacity" {
  description = "GSI write capacity units (for provisioned mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.gsi_write_capacity >= 1 && var.gsi_write_capacity <= 40000
    error_message = "GSI write capacity must be between 1 and 40000."
  }
}

variable "gsi_max_read_capacity" {
  description = "Maximum GSI read capacity for autoscaling"
  type        = number
  default     = 40000
}

variable "gsi_max_write_capacity" {
  description = "Maximum GSI write capacity for autoscaling"
  type        = number
  default     = 40000
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption (optional, uses AWS managed key if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
