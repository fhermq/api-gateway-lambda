# Global Variables - Terraform State Backend Configuration

variable "aws_region" {
  description = "AWS region for global resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "global"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "serverless-monorepo"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
