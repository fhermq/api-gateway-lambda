# Manual E2E Testing Guide

**Date**: February 16, 2026  
**Purpose**: Step-by-step guide for manual end-to-end testing of the serverless infrastructure

## Prerequisites

Before starting manual E2E testing, ensure you have:

- ✅ AWS account with appropriate permissions
- ✅ AWS CLI v2 installed and configured
- ✅ Terraform v1.0+ installed
- ✅ Node.js v18+ installed
- ✅ npm installed
- ✅ Git installed
- ✅ Bash shell available
- ✅ Repository cloned locally
- ✅ All scripts are executable: `chmod +x infrastructure/scripts/*.sh`

## Task 22.1: Deploy Infrastructure to Dev Environment

### Objective
Deploy all infrastructure resources to the dev environment and verify successful creation.

### Step 1: Initialize Terraform Backend

```bash
# Navigate to dev environment directory
cd infrastructure/environments/dev

# Initialize Terraform with S3 backend
terraform init

# Expected output:
# - Backend initialized successfully
# - Terraform state will be stored in S3
# - DynamoDB table will be used for state locking
```

**Verification**:
- [ ] Terraform initialization completes without errors
- [ ] Backend configuration is accepted
- [ ] No state conflicts reported

### Step 2: Review Infrastructure Plan

```bash
# Generate and review the execution plan
terraform plan

# Expected output:
# - Plan to create ~20 resources
# - API Gateway, Lambda, DynamoDB, S3, IAM resources listed
# - No errors or warnings
```

**Verification**:
- [ ] Plan shows all expected resources
- [ ] No errors in the plan
- [ ] Resource count is approximately 20
- [ ] All modules are included

### Step 3: Apply Infrastructure

```bash
# Apply the Terraform configuration
terraform apply

# When prompted, type 'yes' to confirm

# Expected output:
# - All resources created successfully
# - Terraform state updated
# - Outputs displayed (API Gateway URL, Lambda ARN, etc.)
```

**Verification**:
- [ ] All resources created successfully
- [ ] No errors during apply
- [ ] Terraform state is updated
- [ ] Outputs are displayed

### Step 4: Verify Resources in AWS Console

**Lambda Function**:
```bash
# Check Lambda function
aws lambda get-function --function-name api-handler-dev --region us-east-1

# Expected output:
# - Function exists and is active
# - Runtime is nodejs18.x
# - Memory is 256MB
# - Timeout is 60 seconds
```

**DynamoDB Table**:
```bash
# Check DynamoDB table
aws dynamodb describe-table --table-name items-dev --region us-east-1

# Expected output:
# - Table exists and is ACTIVE
# - Billing mode is PAY_PER_REQUEST
# - Has GSI named status-index
# - TTL is enabled
```

**API Gateway**:
```bash
# Check API Gateway
aws apigateway get-rest-apis --region us-east-1

# Expected output:
# - REST API exists
# - Has 5 resources (/items, /items/{id})
# - Has 5 methods (GET, POST, PUT, DELETE, OPTIONS)
```

**S3 Bucket**:
```bash
# Check S3 bucket
aws s3 ls | grep items-dev

# Expected output:
# - S3 bucket exists with name containing 'items-dev'
# - Bucket is accessible
```

**IAM Roles**:
```bash
# Check IAM roles
aws iam list-roles | grep -E "api-handler|lambda"

# Expected output:
# - Lambda_Execution_Role exists
# - Lambda_Deployment_Role exists
# - Infrastructure_Role exists
```

**CloudWatch Log Groups**:
```bash
# Check CloudWatch log groups
aws logs describe-log-groups --region us-east-1 | grep api-handler

# Expected output:
# - Log group /aws/lambda/api-handler-dev exists
# - Retention is set to 30 days
```

### Step 5: Run Post-Deployment Validation

```bash
# Navigate back to project root
cd ../../..

# Run post-deployment validation script
./infrastructure/scripts/01-post-deployment-validation.sh dev

# Expected output:
# - All validations pass
# - Lambda function is active
# - DynamoDB table is active
# - API Gateway is accessible
# - S3 bucket exists
# - IAM role exists
# - CloudWatch log group exists
# - Lambda invocation test passes
# - API Gateway endpoint tests pass
```

**Verification**:
- [ ] All post-deployment validations pass
- [ ] No errors reported
- [ ] All resources are verified
- [ ] Functional tests pass

### Step 6: Capture Terraform Outputs

```bash
# Get Terraform outputs
cd infrastructure/environments/dev
terraform output

# Expected output:
# - api_gateway_url: https://xxxxx.execute-api.us-east-1.amazonaws.com/dev
# - lambda_function_name: api-handler-dev
# - dynamodb_table_name: items-dev
# - s3_bucket_name: xxxxx-items-dev
# - lambda_execution_role_arn: arn:aws:iam::xxxxx:role/xxxxx
# - cloudwatch_log_group_name: /aws/lambda/api-handler-dev
```

**Save these outputs** - you'll need them for the next testing phases.

## Task 22.2: Validate Infrastructure with Validation Scripts

### Objective
Validate infrastructure configuration and identify any issues.

### Step 1: Validate Terraform Configuration

```bash
# Navigate to project root
cd ../../..

# Run infrastructure validation script
./infrastructure/scripts/02-validate-infrastructure.sh dev

# Expected output:
# - All Terraform syntax validations pass
# - All required variables are defined
# - All module outputs are defined
# - IAM policies are least-privilege
# - Backend configuration is correct
# - Module references are correct
# - Encryption is configured
# - Tags are configured
```

**Verification**:
- [ ] All validations pass
- [ ] No errors reported
- [ ] All checks complete successfully
- [ ] Validation report is generated

### Step 2: Detect Orphaned Resources

```bash
# Run orphaned resource detection
./infrastructure/scripts/03-detect-orphaned-resources.sh dev all

# Expected output:
# - No orphaned Lambda functions
# - No orphaned DynamoDB tables
# - No orphaned S3 buckets
# - No orphaned security groups
# - No untagged resources
# - Cost estimation for resources
```

**Verification**:
- [ ] No orphaned resources detected
- [ ] All resources are tagged
- [ ] Cost estimation is provided
- [ ] Detection report is generated

### Step 3: Analyze Costs

```bash
# Run cost analysis
./infrastructure/scripts/04-cost-analysis.sh dev

# Expected output:
# - Lambda cost estimate
# - DynamoDB cost estimate
# - S3 cost estimate
# - CloudWatch cost estimate
# - API Gateway cost estimate
# - Total monthly cost
# - Annual cost estimate
# - Optimization recommendations
```

**Verification**:
- [ ] Cost analysis completes successfully
- [ ] All service costs are estimated
- [ ] Total cost is reasonable for dev environment
- [ ] Optimization recommendations are provided
- [ ] Cost analysis report is generated

## Task 22.3: Test API Gateway Endpoints Manually

### Objective
Test all API Gateway endpoints and verify correct behavior.

### Step 1: Get API Gateway URL

```bash
# Get the API Gateway URL from Terraform outputs
cd infrastructure/environments/dev
API_URL=$(terraform output -raw api_gateway_url)
echo "API URL: $API_URL"

# Expected output:
# API URL: https://xxxxx.execute-api.us-east-1.amazonaws.com/dev
```

### Step 2: Test POST /items Endpoint

```bash
# Create a new item
curl -X POST "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Item 1",
    "description": "This is a test item",
    "status": "active"
  }' | jq .

# Expected output:
# {
#   "statusCode": 201,
#   "body": {
#     "id": "uuid-here",
#     "name": "Test Item 1",
#     "description": "This is a test item",
#     "status": "active",
#     "createdAt": 1234567890,
#     "updatedAt": 1234567890,
#     "createdBy": "system",
#     "version": 1
#   }
# }
```

**Verification**:
- [ ] Status code is 201 (Created)
- [ ] Response includes item ID
- [ ] All required fields are present
- [ ] Timestamps are set correctly
- [ ] Version is 1

**Save the item ID** for use in subsequent tests.

### Step 3: Test GET /items Endpoint

```bash
# Get all items
curl -X GET "$API_URL/items" \
  -H "Content-Type: application/json" | jq .

# Expected output:
# {
#   "statusCode": 200,
#   "body": {
#     "items": [
#       {
#         "id": "uuid-here",
#         "name": "Test Item 1",
#         ...
#       }
#     ],
#     "count": 1
#   }
# }
```

**Verification**:
- [ ] Status code is 200 (OK)
- [ ] Response includes items array
- [ ] Count matches number of items
- [ ] Items have all required fields

### Step 4: Test GET /items/{id} Endpoint

```bash
# Get specific item (replace ITEM_ID with actual ID from Step 2)
ITEM_ID="your-item-id-here"
curl -X GET "$API_URL/items/$ITEM_ID" \
  -H "Content-Type: application/json" | jq .

# Expected output:
# {
#   "statusCode": 200,
#   "body": {
#     "id": "uuid-here",
#     "name": "Test Item 1",
#     ...
#   }
# }
```

**Verification**:
- [ ] Status code is 200 (OK)
- [ ] Response includes correct item
- [ ] Item data matches what was created

### Step 5: Test PUT /items/{id} Endpoint

```bash
# Update the item
curl -X PUT "$API_URL/items/$ITEM_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Test Item 1",
    "description": "This is an updated test item",
    "status": "inactive"
  }' | jq .

# Expected output:
# {
#   "statusCode": 200,
#   "body": {
#     "id": "uuid-here",
#     "name": "Updated Test Item 1",
#     "description": "This is an updated test item",
#     "status": "inactive",
#     "updatedAt": 1234567891,
#     "version": 2
#   }
# }
```

**Verification**:
- [ ] Status code is 200 (OK)
- [ ] Item name is updated
- [ ] Item status is updated
- [ ] updatedAt timestamp is newer
- [ ] Version is incremented to 2

### Step 6: Test DELETE /items/{id} Endpoint

```bash
# Delete the item
curl -X DELETE "$API_URL/items/$ITEM_ID" \
  -H "Content-Type: application/json" -v

# Expected output:
# HTTP/1.1 204 No Content
# (empty body)
```

**Verification**:
- [ ] Status code is 204 (No Content)
- [ ] Response body is empty
- [ ] No errors reported

### Step 7: Verify Item is Deleted

```bash
# Try to get the deleted item
curl -X GET "$API_URL/items/$ITEM_ID" \
  -H "Content-Type: application/json" | jq .

# Expected output:
# {
#   "statusCode": 404,
#   "body": {
#     "error": "NotFoundError",
#     "message": "Item not found"
#   }
# }
```

**Verification**:
- [ ] Status code is 404 (Not Found)
- [ ] Error message indicates item not found

### Step 8: Verify CORS Headers

```bash
# Check CORS headers
curl -i "$API_URL/items" | grep -i "access-control"

# Expected output:
# access-control-allow-origin: *
# access-control-allow-methods: GET,POST,PUT,DELETE,OPTIONS
# access-control-allow-headers: Content-Type,Authorization
```

**Verification**:
- [ ] Access-Control-Allow-Origin header is present
- [ ] Access-Control-Allow-Methods header is present
- [ ] Access-Control-Allow-Headers header is present

## Task 22.4: Test Lambda Function Manually

### Objective
Test Lambda function directly and verify logging.

### Step 1: Verify Lambda Function is Deployed

```bash
# Get Lambda function details
aws lambda get-function --function-name api-handler-dev --region us-east-1

# Expected output:
# - Function exists
# - State is Active
# - Runtime is nodejs18.x
# - Memory is 256MB
# - Timeout is 60 seconds
```

**Verification**:
- [ ] Lambda function exists
- [ ] Function state is Active
- [ ] Configuration is correct

### Step 2: Test Lambda Invocation

```bash
# Invoke Lambda function directly
aws lambda invoke \
  --function-name api-handler-dev \
  --region us-east-1 \
  --payload '{"httpMethod":"GET","path":"/items","headers":{}}' \
  response.json

# Check response
cat response.json | jq .

# Expected output:
# {
#   "statusCode": 200,
#   "headers": {
#     "Content-Type": "application/json",
#     "Access-Control-Allow-Origin": "*"
#   },
#   "body": "{\"items\":[],\"count\":0}"
# }
```

**Verification**:
- [ ] Lambda invocation succeeds
- [ ] Response includes statusCode
- [ ] Response includes headers
- [ ] Response includes body
- [ ] Status code is 200

### Step 3: Check CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/api-handler-dev --follow --region us-east-1

# Expected output:
# - Log entries with timestamps
# - Request ID in each log
# - Log level (INFO, ERROR, etc.)
# - Operation details
# - Duration information
```

**Verification**:
- [ ] CloudWatch logs are being written
- [ ] Logs have timestamps
- [ ] Logs have request IDs
- [ ] Logs have appropriate log levels
- [ ] Logs contain operation details

### Step 4: Verify Structured Logging Format

```bash
# Get recent logs and check format
aws logs get-log-events \
  --log-group-name /aws/lambda/api-handler-dev \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /aws/lambda/api-handler-dev \
    --region us-east-1 \
    --query 'logStreams[0].logStreamName' \
    --output text) \
  --region us-east-1 | jq '.events[0].message'

# Expected output:
# {
#   "timestamp": "2024-01-15T10:30:45.123Z",
#   "requestId": "uuid-here",
#   "level": "INFO",
#   "service": "api-handler",
#   "environment": "dev",
#   "message": "Request received",
#   "httpMethod": "GET",
#   "path": "/items",
#   "statusCode": 200,
#   "duration": 145
# }
```

**Verification**:
- [ ] Logs are in JSON format
- [ ] Timestamp is present
- [ ] Request ID is present
- [ ] Log level is present
- [ ] Service name is present
- [ ] Environment is present
- [ ] Operation details are present

### Step 5: Test Error Logging

```bash
# Invoke Lambda with invalid request
aws lambda invoke \
  --function-name api-handler-dev \
  --region us-east-1 \
  --payload '{"httpMethod":"POST","path":"/items","body":"{}","headers":{"Content-Type":"application/json"}}' \
  error-response.json

# Check response
cat error-response.json | jq .

# Expected output:
# {
#   "statusCode": 400,
#   "body": "{\"error\":\"ValidationError\",\"message\":\"Missing required field: name\"}"
# }
```

**Verification**:
- [ ] Lambda returns 400 for invalid input
- [ ] Error message is descriptive
- [ ] Error is logged to CloudWatch

## Task 22.5: Test DynamoDB Operations Manually

### Objective
Test DynamoDB table and verify CRUD operations.

### Step 1: Verify DynamoDB Table Exists

```bash
# Describe DynamoDB table
aws dynamodb describe-table --table-name items-dev --region us-east-1

# Expected output:
# - Table exists
# - Status is ACTIVE
# - Billing mode is PAY_PER_REQUEST
# - Has GSI named status-index
# - TTL is enabled
```

**Verification**:
- [ ] Table exists
- [ ] Table status is ACTIVE
- [ ] Billing mode is on-demand
- [ ] GSI is created
- [ ] TTL is enabled

### Step 2: Verify Table Schema

```bash
# Check table attributes
aws dynamodb describe-table --table-name items-dev --region us-east-1 \
  --query 'Table.AttributeDefinitions' | jq .

# Expected output:
# [
#   {"AttributeName": "id", "AttributeType": "S"},
#   {"AttributeName": "status", "AttributeType": "S"},
#   {"AttributeName": "createdAt", "AttributeType": "N"}
# ]
```

**Verification**:
- [ ] Primary key (id) is defined
- [ ] GSI attributes (status, createdAt) are defined
- [ ] Attribute types are correct

### Step 3: Test CRUD Operations via Lambda

```bash
# Create item via API
ITEM_RESPONSE=$(curl -s -X POST "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "DynamoDB Test Item",
    "description": "Testing DynamoDB operations",
    "status": "active"
  }')

ITEM_ID=$(echo $ITEM_RESPONSE | jq -r '.body.id')
echo "Created item: $ITEM_ID"

# Read item via API
curl -s -X GET "$API_URL/items/$ITEM_ID" | jq '.body'

# Update item via API
curl -s -X PUT "$API_URL/items/$ITEM_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated DynamoDB Test Item"}' | jq '.body'

# Delete item via API
curl -s -X DELETE "$API_URL/items/$ITEM_ID"

# Verify deletion
curl -s -X GET "$API_URL/items/$ITEM_ID" | jq '.body'
```

**Verification**:
- [ ] Create operation succeeds (201)
- [ ] Read operation returns correct item (200)
- [ ] Update operation succeeds (200)
- [ ] Delete operation succeeds (204)
- [ ] Deleted item cannot be retrieved (404)

### Step 4: Verify Data Persistence

```bash
# Query DynamoDB directly
aws dynamodb scan --table-name items-dev --region us-east-1 | jq '.Items'

# Expected output:
# [
#   {
#     "id": {"S": "uuid-here"},
#     "name": {"S": "Item Name"},
#     "status": {"S": "active"},
#     "createdAt": {"N": "1234567890"},
#     "updatedAt": {"N": "1234567890"}
#   }
# ]
```

**Verification**:
- [ ] Items are persisted in DynamoDB
- [ ] Item data matches what was created
- [ ] All attributes are present

## Task 22.6: Test OIDC Authentication Manually

### Objective
Verify GitHub OIDC provider configuration.

### Step 1: Verify OIDC Provider Exists

```bash
# List OIDC providers
aws iam list-open-id-connect-providers --region us-east-1

# Expected output:
# {
#   "OpenIDConnectProviderList": [
#     {
#       "Arn": "arn:aws:iam::xxxxx:oidc-provider/token.actions.githubusercontent.com"
#     }
#   ]
# }
```

**Verification**:
- [ ] OIDC provider exists
- [ ] Provider is for GitHub (token.actions.githubusercontent.com)

### Step 2: Verify IAM Roles Exist

```bash
# List IAM roles
aws iam list-roles --region us-east-1 | grep -E "Infrastructure_Role|Lambda_Deployment_Role|Lambda_Execution_Role"

# Expected output:
# - Infrastructure_Role exists
# - Lambda_Deployment_Role exists
# - Lambda_Execution_Role exists
```

**Verification**:
- [ ] All required roles exist
- [ ] Roles are properly named

### Step 3: Verify Role Trust Relationships

```bash
# Check Infrastructure_Role trust relationship
aws iam get-role --role-name Infrastructure_Role --region us-east-1 \
  --query 'Role.AssumeRolePolicyDocument' | jq .

# Expected output:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "arn:aws:iam::xxxxx:oidc-provider/token.actions.githubusercontent.com"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringEquals": {
#           "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
#         },
#         "StringLike": {
#           "token.actions.githubusercontent.com:sub": "repo:owner/repo:*"
#         }
#       }
#     }
#   ]
# }
```

**Verification**:
- [ ] Trust relationship allows OIDC provider
- [ ] Condition restricts to correct repository
- [ ] Action is sts:AssumeRoleWithWebIdentity

### Step 4: Verify Role Permissions

```bash
# Check Infrastructure_Role permissions
aws iam list-attached-role-policies --role-name Infrastructure_Role --region us-east-1

# Expected output:
# {
#   "AttachedPolicies": [
#     {
#       "PolicyName": "InfrastructurePolicy",
#       "PolicyArn": "arn:aws:iam::xxxxx:policy/InfrastructurePolicy"
#     }
#   ]
# }
```

**Verification**:
- [ ] Role has attached policies
- [ ] Policies are appropriate for infrastructure management

## Summary of Manual Testing

### Deployment Verification
- [ ] All Terraform resources created successfully
- [ ] All resources are in correct state (Active, ACTIVE, etc.)
- [ ] All outputs are displayed correctly

### Infrastructure Validation
- [ ] Terraform configuration is valid
- [ ] No orphaned resources detected
- [ ] Cost analysis is reasonable

### API Gateway Testing
- [ ] POST /items returns 201
- [ ] GET /items returns 200
- [ ] GET /items/{id} returns 200 or 404
- [ ] PUT /items/{id} returns 200
- [ ] DELETE /items/{id} returns 204
- [ ] CORS headers are present

### Lambda Testing
- [ ] Lambda function is active
- [ ] Lambda invocation succeeds
- [ ] CloudWatch logs are written
- [ ] Logs are in structured JSON format

### DynamoDB Testing
- [ ] Table exists and is active
- [ ] CRUD operations work correctly
- [ ] Data is persisted correctly
- [ ] Queries return expected results

### OIDC Testing
- [ ] OIDC provider is configured
- [ ] IAM roles exist
- [ ] Trust relationships are correct
- [ ] Role permissions are appropriate

## Troubleshooting

### Issue: Terraform Apply Fails
**Solution**:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Check Terraform syntax: `terraform validate`
3. Review error message in detail
4. Check AWS console for resource conflicts

### Issue: Lambda Function Not Responding
**Solution**:
1. Check Lambda logs: `aws logs tail /aws/lambda/api-handler-dev`
2. Check Lambda configuration
3. Verify IAM role permissions
4. Test Lambda invocation directly

### Issue: API Gateway Returns 403
**Solution**:
1. Verify API Gateway exists
2. Check Lambda integration
3. Verify CORS configuration
4. Check CloudWatch logs

### Issue: DynamoDB Operations Fail
**Solution**:
1. Verify table exists and is ACTIVE
2. Check IAM role permissions
3. Verify table schema
4. Check CloudWatch logs for errors

## Next Steps

After completing all manual E2E testing:

1. Document all test results
2. Address any issues found
3. Retest fixed functionality
4. Proceed to Task 23 (Infrastructure Destruction Testing)
5. Proceed to Task 24 (Final Checkpoint)

---

**Manual E2E Testing Guide Complete**
