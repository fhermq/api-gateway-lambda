variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming (e.g., api-gateway-lambda)"
  type        = string
  validation {
    condition     = length(var.project_name) > 0 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization name must not be empty."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  validation {
    condition     = length(var.github_repo) > 0
    error_message = "GitHub repository name must not be empty."
  }
}

variable "github_branch" {
  description = "GitHub branch for OIDC trust policy"
  type        = string
  default     = "main"
  validation {
    condition     = length(var.github_branch) > 0
    error_message = "GitHub branch must not be empty."
  }
}
