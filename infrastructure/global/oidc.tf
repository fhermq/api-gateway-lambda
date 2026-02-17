# GitHub OIDC Provider for AWS
# Uses existing GitHub OIDC provider configured in AWS account

# Data source to get existing GitHub OIDC Provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Output the OIDC provider ARN for use in IAM role trust relationships
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github.url
}
