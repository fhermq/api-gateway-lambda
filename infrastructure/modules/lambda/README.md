# Lambda Module

This Terraform module creates and manages AWS Lambda functions for the serverless application.

## Overview

The Lambda module provisions:
- Lambda function for API handler (CRUD operations)
- CloudWatch Log Group with configurable retention
- Optional Lambda alias for versioning
- Optional CloudWatch alarms for monitoring
- Optional VPC configuration
- Optional X-Ray tracing

## Features

- **Structured Logging**: JSON-formatted logs to CloudWatch
- **Environment Variables**: Configurable environment variables for DynamoDB table name and environment
- **Monitoring**: Optional CloudWatch alarms for errors, throttles, and duration
- **Versioning**: Optional Lambda alias for managing versions
- **VPC Support**: Optional VPC configuration for private Lambda functions
- **X-Ray Tracing**: Optional distributed tracing support
- **Concurrency Control**: Optional reserved concurrent executions

## Usage

```hcl
module "lambda" {
  source = "./modules/lambda"

  environment                 = "dev"
  project_name                = "serverless-app"
  lambda_code_path            = "${path.module}/../apps/api-handler/dist/lambda.zip"
  lambda_handler              = "index.handler"
  lambda_runtime              = "nodejs18.x"
  lambda_timeout              = 30
  lambda_memory               = 256
  lambda_execution_role_arn   = aws_iam_role.lambda_execution.arn
  dynamodb_table_name         = aws_dynamodb_table.items.name
  log_retention_days          = 30
  log_level                   = "INFO"
  create_alarms               = true
  create_alias                = false

  tags = {
    Environment = "dev"
    Project     = "serverless-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | string | - | yes |
| project_name | Project name for resource naming | string | - | yes |
| lambda_code_path | Path to the Lambda function code (zip file) | string | - | yes |
| lambda_handler | Lambda handler function (e.g., index.handler) | string | "index.handler" | no |
| lambda_runtime | Lambda runtime environment | string | "nodejs18.x" | no |
| lambda_timeout | Lambda function timeout in seconds | number | 30 | no |
| lambda_memory | Lambda function memory in MB | number | 256 | no |
| lambda_execution_role_arn | ARN of the IAM role for Lambda execution | string | - | yes |
| dynamodb_table_name | Name of the DynamoDB table | string | - | yes |
| log_retention_days | CloudWatch log retention in days | number | 30 | no |
| log_level | Log level for Lambda function | string | "INFO" | no |
| vpc_subnet_ids | List of VPC subnet IDs (optional) | list(string) | null | no |
| vpc_security_group_ids | List of VPC security group IDs (optional) | list(string) | null | no |
| enable_xray_tracing | Enable X-Ray tracing | bool | false | no |
| reserved_concurrent_executions | Reserved concurrent executions | number | null | no |
| create_alias | Create a Lambda alias for versioning | bool | false | no |
| create_alarms | Create CloudWatch alarms | bool | true | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | ARN of the Lambda function |
| function_name | Name of the Lambda function |
| function_invoke_arn | Invoke ARN of the Lambda function |
| function_version | Latest version of the Lambda function |
| function_qualified_arn | Qualified ARN of the Lambda function |
| cloudwatch_log_group_name | CloudWatch log group name |
| cloudwatch_log_group_arn | CloudWatch log group ARN |
| alias_arn | ARN of the Lambda alias (if created) |
| alias_name | Name of the Lambda alias (if created) |
| function_role_arn | ARN of the IAM role |
| function_timeout | Timeout in seconds |
| function_memory | Memory in MB |
| function_runtime | Runtime environment |
| function_environment_variables | Environment variables (sensitive) |

## Environment Variables

The Lambda function receives the following environment variables:

- `DYNAMODB_TABLE_NAME`: Name of the DynamoDB table for CRUD operations
- `ENVIRONMENT`: Environment name (dev, staging, prod)
- `PROJECT_NAME`: Project name
- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARN, ERROR)

## CloudWatch Logs

The module creates a CloudWatch Log Group with the following naming convention:
```
/aws/lambda/{project_name}-api-handler-{environment}
```

Logs are retained for the specified number of days (default: 30 days).

## CloudWatch Alarms

When `create_alarms` is set to `true`, the module creates three alarms:

1. **Errors Alarm**: Triggers when Lambda errors exceed 5 in 5 minutes
2. **Throttles Alarm**: Triggers when Lambda is throttled
3. **Duration Alarm**: Triggers when average duration exceeds 80% of timeout

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0
- Lambda function code packaged as a zip file
- IAM role for Lambda execution with appropriate permissions

## Notes

- The Lambda function code must be provided as a zip file
- The `lambda_execution_role_arn` must have permissions to access DynamoDB and CloudWatch Logs
- For VPC Lambda functions, ensure security groups allow outbound access to DynamoDB and CloudWatch Logs
- X-Ray tracing requires the Lambda execution role to have X-Ray write permissions
