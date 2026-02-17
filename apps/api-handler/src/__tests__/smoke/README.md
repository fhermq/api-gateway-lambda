# Smoke Tests

Smoke tests are quick validation tests that verify basic functionality after Lambda deployment. They test the deployed infrastructure without requiring AWS credentials or complex setup.

## Overview

Smoke tests validate:
- ✅ API Gateway endpoint accessibility
- ✅ Lambda function invocation
- ✅ DynamoDB table accessibility
- ✅ CloudWatch logs are being written
- ✅ CORS headers are present
- ✅ API response format
- ✅ Error handling
- ✅ Content-Type headers
- ✅ CRUD operations (create, read, update, delete)
- ✅ Response time performance

## Running Smoke Tests

### Option 1: Run with Jest (Recommended for CI/CD)

```bash
# Run all smoke tests
npm test -- smoke-tests.jest.test.ts

# Run with specific environment
API_GATEWAY_URL=https://api.example.com npm test -- smoke-tests.jest.test.ts

# Run with all environment variables
API_GATEWAY_URL=https://api.example.com \
LAMBDA_FUNCTION_NAME=api-handler-prod \
DYNAMODB_TABLE_NAME=items-prod \
AWS_REGION=us-east-1 \
ENVIRONMENT=prod \
npm test -- smoke-tests.jest.test.ts
```

### Option 2: Run as Standalone Script

```bash
# Run standalone smoke tests
node apps/api-handler/src/__tests__/smoke/smoke-tests.test.ts

# Run with environment variables
API_GATEWAY_URL=https://api.example.com \
LAMBDA_FUNCTION_NAME=api-handler-prod \
DYNAMODB_TABLE_NAME=items-prod \
AWS_REGION=us-east-1 \
ENVIRONMENT=prod \
node apps/api-handler/src/__tests__/smoke/smoke-tests.test.ts
```

## Environment Variables

Configure smoke tests using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_GATEWAY_URL` | `http://localhost:3000` | API Gateway endpoint URL |
| `LAMBDA_FUNCTION_NAME` | `api-handler-dev` | Lambda function name |
| `DYNAMODB_TABLE_NAME` | `items-dev` | DynamoDB table name |
| `AWS_REGION` | `us-east-1` | AWS region |
| `ENVIRONMENT` | `dev` | Environment name (dev, staging, prod) |

## Test Details

### Test 1: API Gateway Endpoint Accessibility
- **Purpose**: Verify API Gateway is accessible and responding
- **Method**: GET /items
- **Expected**: 200 status code
- **Validates**: Requirements 9.6, 15.5

### Test 2: Lambda Function Invocation
- **Purpose**: Verify Lambda function is deployed and callable
- **Method**: POST /items with test data
- **Expected**: 201 status code with created item
- **Validates**: Requirements 9.6, 15.5

### Test 3: DynamoDB Table Accessibility
- **Purpose**: Verify DynamoDB table is accessible and working
- **Method**: Create item, then read it back
- **Expected**: Both operations succeed
- **Validates**: Requirements 9.6, 15.5

### Test 4: CloudWatch Logs Are Being Written
- **Purpose**: Verify CloudWatch logs are being written
- **Method**: Make request and verify response
- **Expected**: Request completes successfully
- **Note**: Actual log verification requires CloudWatch API access
- **Validates**: Requirements 9.6, 15.5

### Test 5: CORS Headers Are Present
- **Purpose**: Verify CORS headers are included in responses
- **Method**: GET /items and check headers
- **Expected**: Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers present
- **Validates**: Requirements 12.8, 15.5

### Test 6: API Response Format
- **Purpose**: Verify API returns correct response format
- **Method**: GET /items and validate structure
- **Expected**: Response has `items` array and `count` field
- **Validates**: Requirements 9.6, 15.5

### Test 7: Error Handling
- **Purpose**: Verify error handling is working
- **Method**: GET /items/non-existent-id
- **Expected**: 404 status with error and message fields
- **Validates**: Requirements 9.6, 15.5

### Test 8: Content-Type Headers
- **Purpose**: Verify Content-Type header is correct
- **Method**: GET /items and check Content-Type header
- **Expected**: application/json
- **Validates**: Requirements 9.6, 15.5

### Test 9: CRUD Operations
- **Purpose**: Verify all CRUD operations work end-to-end
- **Method**: Create, read, update, delete item
- **Expected**: All operations succeed with correct status codes
- **Validates**: Requirements 9.6, 15.5

### Test 10: Response Time
- **Purpose**: Verify API responds within acceptable time
- **Method**: Measure response time for GET /items
- **Expected**: Response time < 5 seconds
- **Validates**: Requirements 9.6, 15.5

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Run Smoke Tests
  env:
    API_GATEWAY_URL: ${{ steps.deploy.outputs.api_gateway_url }}
    LAMBDA_FUNCTION_NAME: api-handler-${{ matrix.environment }}
    DYNAMODB_TABLE_NAME: items-${{ matrix.environment }}
    AWS_REGION: us-east-1
    ENVIRONMENT: ${{ matrix.environment }}
  run: npm test -- smoke-tests.jest.test.ts
```

## Troubleshooting

### Tests Fail with Connection Error

**Problem**: `Error: connect ECONNREFUSED`

**Solution**: Verify API Gateway URL is correct and accessible:
```bash
curl -v https://your-api-gateway-url/items
```

### Tests Fail with 404 Not Found

**Problem**: `API Gateway returned status 404`

**Solution**: Verify the API Gateway endpoint is deployed and routes are configured correctly.

### Tests Fail with 500 Internal Server Error

**Problem**: `Lambda function returned status 500`

**Solution**: Check Lambda function logs in CloudWatch:
```bash
aws logs tail /aws/lambda/api-handler-dev --follow
```

### Tests Timeout

**Problem**: Tests hang or timeout

**Solution**: Increase Jest timeout:
```bash
npm test -- smoke-tests.jest.test.ts --testTimeout=30000
```

## Output Example

```
========================================
🚀 Starting Smoke Tests
========================================

Environment: dev
API Gateway URL: https://api.example.com
Lambda Function: api-handler-dev
DynamoDB Table: items-dev
AWS Region: us-east-1

🧪 Test 1: API Gateway Endpoint Accessibility
✅ API Gateway is accessible

🧪 Test 2: Lambda Function Invocation
✅ Lambda function is invoked and working

🧪 Test 3: DynamoDB Table Accessibility
✅ DynamoDB table is accessible and working

🧪 Test 4: CloudWatch Logs Are Being Written
✅ Request completed (CloudWatch logs should be written)
   Note: Verify logs in CloudWatch console for confirmation

🧪 Test 5: CORS Headers Are Present
✅ CORS headers are present
   Allow-Origin: *
   Allow-Methods: GET,POST,PUT,DELETE
   Allow-Headers: Content-Type

🧪 Test 6: API Response Format
✅ API response format is correct
   Items count: 5

🧪 Test 7: Error Handling
✅ Error handling is working correctly
   404 Error: Item not found

🧪 Test 8: Content-Type Headers
✅ Content-Type header is correct
   Content-Type: application/json

🧪 Test 9: CRUD Operations
✅ All CRUD operations are working

🧪 Test 10: Response Time
✅ Response time is acceptable
   Response time: 245ms

========================================
📊 Smoke Test Summary
========================================

✅ PASS: apiGatewayAccessibility
✅ PASS: lambdaFunctionInvocation
✅ PASS: dynamodbTableAccessibility
✅ PASS: cloudwatchLogsWritten
✅ PASS: corsHeadersPresent
✅ PASS: apiResponseFormat
✅ PASS: errorHandling
✅ PASS: contentTypeHeaders
✅ PASS: crudOperations
✅ PASS: responseTime

Total: 10 passed, 0 failed
Success Rate: 100.0%

🎉 All smoke tests passed!
```

## Best Practices

1. **Run After Deployment**: Always run smoke tests after deploying Lambda code
2. **Use in CI/CD**: Include smoke tests in your deployment pipeline
3. **Monitor Response Times**: Track response times to detect performance regressions
4. **Test All Environments**: Run smoke tests against dev, staging, and production
5. **Check CloudWatch Logs**: Manually verify CloudWatch logs are being written
6. **Document Failures**: If tests fail, document the issue and root cause

## Requirements Validation

Smoke tests validate the following requirements:

- **Requirement 9.6**: Lambda code deployment workflow runs smoke tests
- **Requirement 15.5**: Smoke tests verify basic functionality after Lambda deployment

## See Also

- [Unit Tests](../unit/README.md)
- [Integration Tests](../integration/README.md)
- [Lambda Deployment Workflow](.github/workflows/lambda-deployment.yml)
