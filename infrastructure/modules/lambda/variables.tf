# Lambda Module Variables

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

variable "lambda_code_path" {
  description = "Path to the Lambda function code (zip file)"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler function (e.g., index.handler)"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime environment"
  type        = string
  default     = "nodejs18.x"
  validation {
    condition     = contains(["nodejs18.x", "nodejs20.x", "nodejs16.x"], var.lambda_runtime)
    error_message = "Lambda runtime must be a supported Node.js version."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
  validation {
    condition     = var.lambda_memory >= 128 && var.lambda_memory <= 10240 && var.lambda_memory % 1 == 0
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for the Lambda function"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch value."
  }
}

variable "log_level" {
  description = "Log level for Lambda function (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be DEBUG, INFO, WARN, or ERROR."
  }
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for Lambda function (optional)"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for Lambda function (optional)"
  type        = list(string)
  default     = null
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Lambda function"
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda function (optional)"
  type        = number
  default     = -1
  validation {
    condition     = var.reserved_concurrent_executions == -1 || (var.reserved_concurrent_executions >= 0 && var.reserved_concurrent_executions <= 1000)
    error_message = "Reserved concurrent executions must be between 0 and 1000 or -1 for no limit."
  }
}

variable "create_alias" {
  description = "Create a Lambda alias for versioning"
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Create CloudWatch alarms for Lambda function"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
