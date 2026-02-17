# API Gateway Module - REST API for CRUD Operations

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# ============================================================================
# CloudWatch Log Group for API Gateway
# ============================================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-gateway-logs-${var.environment}"
      Environment = var.environment
      Purpose     = "API Gateway Request Logging"
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# API Gateway REST API
# ============================================================================

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "REST API for ${var.project_name} - ${var.environment} environment"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-${var.environment}"
      Environment = var.environment
      Purpose     = "REST API for CRUD Operations"
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# API Gateway Account (for CloudWatch Logs)
# ============================================================================

resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# ============================================================================
# IAM Role for API Gateway CloudWatch Logs
# ============================================================================

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-api-gateway-cloudwatch-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-gateway-cloudwatch-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${var.project_name}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*"
      }
    ]
  })
}

# ============================================================================
# API Gateway Stage
# ============================================================================

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId          = "$$context.requestId"
      ip                 = "$$context.identity.sourceIp"
      requestTime        = "$$context.requestTime"
      httpMethod         = "$$context.httpMethod"
      resourcePath       = "$$context.resourcePath"
      status             = "$$context.status"
      protocol           = "$$context.protocol"
      responseLength     = "$$context.responseLength"
      integrationLatency = "$$context.integration.latency"
      error              = "$$context.error.message"
      errorType          = "$$context.error.messageString"
    })
  }

  variables = {
    environment = var.environment
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-stage-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_api_gateway_account.api]
}

# ============================================================================
# /items Resource
# ============================================================================

resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# ============================================================================
# /items/{id} Resource
# ============================================================================

resource "aws_api_gateway_resource" "item_by_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
}

# ============================================================================
# POST /items - Create Item
# ============================================================================

resource "aws_api_gateway_method" "post_items" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.items.id
  http_method          = "POST"
  authorization        = "NONE"
  request_models       = { "application/json" = aws_api_gateway_model.item_create.name }
  request_validator_id = aws_api_gateway_request_validator.all.id
}

resource "aws_api_gateway_integration" "post_items" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.post_items.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "post_items_201" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method
  status_code = "201"

  response_models = {
    "application/json" = aws_api_gateway_model.item_response.name
  }

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "post_items_400" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method
  status_code = "400"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

resource "aws_api_gateway_method_response" "post_items_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

# ============================================================================
# GET /items - List Items
# ============================================================================

resource "aws_api_gateway_method" "get_items" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.items.id
  http_method          = "GET"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.all.id

  request_parameters = {
    "method.request.querystring.limit"  = false
    "method.request.querystring.offset" = false
  }
}

resource "aws_api_gateway_integration" "get_items" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get_items.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "get_items_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.get_items.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.items_list_response.name
  }

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "get_items_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.get_items.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

# ============================================================================
# GET /items/{id} - Get Item by ID
# ============================================================================

resource "aws_api_gateway_method" "get_item_by_id" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.item_by_id.id
  http_method          = "GET"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.all.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "get_item_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item_by_id.id
  http_method             = aws_api_gateway_method.get_item_by_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "get_item_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.get_item_by_id.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.item_response.name
  }

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "get_item_by_id_404" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.get_item_by_id.http_method
  status_code = "404"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

resource "aws_api_gateway_method_response" "get_item_by_id_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.get_item_by_id.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

# ============================================================================
# PUT /items/{id} - Update Item
# ============================================================================

resource "aws_api_gateway_method" "put_item_by_id" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.item_by_id.id
  http_method          = "PUT"
  authorization        = "NONE"
  request_models       = { "application/json" = aws_api_gateway_model.item_update.name }
  request_validator_id = aws_api_gateway_request_validator.all.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "put_item_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item_by_id.id
  http_method             = aws_api_gateway_method.put_item_by_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "put_item_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.put_item_by_id.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.item_response.name
  }

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "put_item_by_id_400" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.put_item_by_id.http_method
  status_code = "400"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

resource "aws_api_gateway_method_response" "put_item_by_id_404" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.put_item_by_id.http_method
  status_code = "404"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

resource "aws_api_gateway_method_response" "put_item_by_id_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.put_item_by_id.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

# ============================================================================
# DELETE /items/{id} - Delete Item
# ============================================================================

resource "aws_api_gateway_method" "delete_item_by_id" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.item_by_id.id
  http_method          = "DELETE"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.all.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "delete_item_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item_by_id.id
  http_method             = aws_api_gateway_method.delete_item_by_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "delete_item_by_id_204" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.delete_item_by_id.http_method
  status_code = "204"
}

resource "aws_api_gateway_method_response" "delete_item_by_id_404" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.delete_item_by_id.http_method
  status_code = "404"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

resource "aws_api_gateway_method_response" "delete_item_by_id_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.delete_item_by_id.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error_response.name
  }
}

# ============================================================================
# CORS Configuration for All Methods
# ============================================================================

resource "aws_api_gateway_method" "options_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.options_items.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.options_items.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_items]
}

resource "aws_api_gateway_method_response" "options_items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.options_items.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method" "options_item_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item_by_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_item_by_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.options_item_by_id.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_item_by_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.options_item_by_id.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_item_by_id]
}

resource "aws_api_gateway_method_response" "options_item_by_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_by_id.id
  http_method = aws_api_gateway_method.options_item_by_id.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# ============================================================================
# Request Validator
# ============================================================================

resource "aws_api_gateway_request_validator" "all" {
  name                        = "${var.project_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# ============================================================================
# Request/Response Models
# ============================================================================

resource "aws_api_gateway_model" "item_create" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ItemCreate"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    properties = {
      name = {
        type        = "string"
        minLength   = 1
        maxLength   = 255
        description = "Item name"
      }
      description = {
        type        = "string"
        maxLength   = 1000
        description = "Item description"
      }
      status = {
        type        = "string"
        enum        = ["active", "inactive", "archived"]
        description = "Item status"
      }
    }
    required = ["name"]
  })
}

resource "aws_api_gateway_model" "item_update" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ItemUpdate"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    properties = {
      name = {
        type        = "string"
        minLength   = 1
        maxLength   = 255
        description = "Item name"
      }
      description = {
        type        = "string"
        maxLength   = 1000
        description = "Item description"
      }
      status = {
        type        = "string"
        enum        = ["active", "inactive", "archived"]
        description = "Item status"
      }
    }
  })
}

resource "aws_api_gateway_model" "item_response" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ItemResponse"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    properties = {
      id = {
        type        = "string"
        description = "Item ID"
      }
      name = {
        type        = "string"
        description = "Item name"
      }
      description = {
        type        = "string"
        description = "Item description"
      }
      status = {
        type        = "string"
        description = "Item status"
      }
      createdAt = {
        type        = "number"
        description = "Creation timestamp"
      }
      updatedAt = {
        type        = "number"
        description = "Last update timestamp"
      }
      createdBy = {
        type        = "string"
        description = "User who created the item"
      }
      version = {
        type        = "number"
        description = "Item version"
      }
    }
  })
}

resource "aws_api_gateway_model" "items_list_response" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ItemsListResponse"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    properties = {
      items = {
        type = "array"
        items = {
          type = "object"
          properties = {
            id = {
              type = "string"
            }
            name = {
              type = "string"
            }
            description = {
              type = "string"
            }
            status = {
              type = "string"
            }
            createdAt = {
              type = "number"
            }
            updatedAt = {
              type = "number"
            }
            createdBy = {
              type = "string"
            }
            version = {
              type = "number"
            }
          }
        }
        description = "List of items"
      }
      count = {
        type        = "number"
        description = "Total count of items"
      }
      nextToken = {
        type        = "string"
        description = "Pagination token for next page"
      }
    }
  })
}

resource "aws_api_gateway_model" "error_response" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ErrorResponse"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    properties = {
      error = {
        type        = "string"
        description = "Error type"
      }
      message = {
        type        = "string"
        description = "Error message"
      }
      requestId = {
        type        = "string"
        description = "Request ID for tracking"
      }
      timestamp = {
        type        = "number"
        description = "Error timestamp"
      }
    }
  })
}

# ============================================================================
# API Gateway Deployment
# ============================================================================

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.post_items,
    aws_api_gateway_integration.get_items,
    aws_api_gateway_integration.get_item_by_id,
    aws_api_gateway_integration.put_item_by_id,
    aws_api_gateway_integration.delete_item_by_id,
    aws_api_gateway_integration.options_items,
    aws_api_gateway_integration.options_item_by_id,
    aws_api_gateway_integration_response.options_items,
    aws_api_gateway_integration_response.options_item_by_id,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Lambda Permission for API Gateway
# ============================================================================

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
