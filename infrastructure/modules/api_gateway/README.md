# API Gateway Module

This Terraform module creates a REST API Gateway with CRUD endpoints for the serverless application.

## Overview

The API Gateway module provisions:
- REST API with regional endpoint
- Five CRUD endpoints: POST /items, GET /items, GET /items/{id}, PUT /items/{id}, DELETE /items/{id}
- CORS configuration for all endpoints
- Request/response models with validation
- CloudWatch logging for all API requests
- Lambda integration for all endpoints

## Resources Created

- `aws_api_gateway_rest_api`: REST API definition
- `aws_api_gateway_resource`: API resources (/items, /items/{id})
- `aws_api_gateway_method`: HTTP methods for each endpoint
- `aws_api_gateway_integration`: Lambda integration for each method
- `aws_api_gateway_model`: Request/response validation models
- `aws_api_gateway_stage`: API stage with CloudWatch logging
- `aws_api_gateway_deployment`: API deployment
- `aws_cloudwatch_log_group`: CloudWatch logs for API requests
- `aws_iam_role`: IAM role for API Gateway CloudWatch logging
- `aws_lambda_permission`: Permission for API Gateway to invoke Lambda

## Endpoints

### POST /items
Create a new item.

**Request Body:**
```json
{
  "name": "string (required, max 255 chars)",
  "description": "string (optional, max 1000 chars)",
  "status": "string (optional, enum: active|inactive|archived)"
}
```

**Response:** 201 Created
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "status": "string",
  "createdAt": "number",
  "updatedAt": "number",
  "createdBy": "string",
  "version": "number"
}
```

### GET /items
List all items with optional pagination.

**Query Parameters:**
- `limit` (optional): Number of items to return (default: all)
- `offset` (optional): Number of items to skip (default: 0)

**Response:** 200 OK
```json
{
  "items": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "status": "string",
      "createdAt": "number",
      "updatedAt": "number",
      "createdBy": "string",
      "version": "number"
    }
  ],
  "count": "number",
  "nextToken": "string (optional)"
}
```

### GET /items/{id}
Retrieve a single item by ID.

**Path Parameters:**
- `id` (required): Item ID

**Response:** 200 OK
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "status": "string",
  "createdAt": "number",
  "updatedAt": "number",
  "createdBy": "string",
  "version": "number"
}
```

**Error Response:** 404 Not Found

### PUT /items/{id}
Update an existing item.

**Path Parameters:**
- `id` (required): Item ID

**Request Body:**
```json
{
  "name": "string (optional, max 255 chars)",
  "description": "string (optional, max 1000 chars)",
  "status": "string (optional, enum: active|inactive|archived)"
}
```

**Response:** 200 OK
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "status": "string",
  "createdAt": "number",
  "updatedAt": "number",
  "createdBy": "string",
  "version": "number"
}
```

**Error Responses:**
- 400 Bad Request (validation error)
- 404 Not Found

### DELETE /items/{id}
Delete an item.

**Path Parameters:**
- `id` (required): Item ID

**Response:** 204 No Content

**Error Response:** 404 Not Found

## CORS Configuration

All endpoints support CORS with the following headers:
- `Access-Control-Allow-Origin`: * (configurable)
- `Access-Control-Allow-Methods`: GET, POST, PUT, DELETE, OPTIONS
- `Access-Control-Allow-Headers`: Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token

## CloudWatch Logging

All API requests are logged to CloudWatch with the following information:
- Request ID
- Source IP
- Request time
- HTTP method
- Resource path
- Response status code
- Protocol
- Response length
- Integration latency
- Error messages (if any)

Log retention is configurable (default: 30 days).

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (dev, staging, prod) | string | - | yes |
| project_name | Project name for resource naming | string | - | yes |
| lambda_invoke_arn | ARN of the Lambda function for invocation | string | - | yes |
| lambda_function_name | Name of the Lambda function | string | - | yes |
| log_retention_days | CloudWatch log retention in days | number | 30 | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| api_id | API Gateway REST API ID |
| api_arn | API Gateway REST API ARN |
| api_endpoint | API Gateway REST API endpoint URL |
| stage_name | API Gateway stage name |
| stage_invoke_url | API Gateway stage invoke URL |
| cloudwatch_log_group_name | CloudWatch log group name for API Gateway |
| cloudwatch_log_group_arn | CloudWatch log group ARN for API Gateway |
| request_validator_id | API Gateway request validator ID |

## Usage Example

```hcl
module "api_gateway" {
  source = "./modules/api_gateway"

  environment           = "dev"
  project_name          = "serverless-monorepo"
  lambda_invoke_arn     = aws_lambda_function.api_handler.invoke_arn
  lambda_function_name  = aws_lambda_function.api_handler.function_name
  log_retention_days    = 30

  tags = {
    Environment = "dev"
    Project     = "serverless-monorepo"
  }
}
```

## Notes

- The API Gateway uses AWS_PROXY integration with Lambda, meaning the Lambda function receives the full request and must return a properly formatted response.
- Request validation is enabled for all endpoints to validate request bodies and parameters against the defined models.
- CORS is configured to allow requests from all origins (*). For production, consider restricting this to specific origins.
- CloudWatch logging is enabled for all API requests with detailed information for debugging and monitoring.
- The module automatically creates the necessary IAM role and permissions for API Gateway to write logs to CloudWatch.
