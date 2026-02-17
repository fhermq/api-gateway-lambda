# Design Document: Serverless Monorepo AWS

## Overview

The Serverless Monorepo AWS system is a production-ready infrastructure framework that combines Infrastructure as Code (Terraform), serverless compute (Lambda), NoSQL database (DynamoDB), and CI/CD automation (GitHub Actions) into a unified monorepo. The architecture emphasizes security through OIDC-based authentication, least-privilege IAM roles, and encrypted state management.

### Key Design Principles

1. **Security First**: Zero hardcoded secrets, OIDC-based authentication, least-privilege IAM roles
2. **Infrastructure as Code**: All AWS resources defined in Terraform for version control and reproducibility
3. **Separation of Concerns**: Distinct layers for infrastructure, applications, and data
4. **Automation**: GitHub Actions workflows for consistent, repeatable deployments
5. **Observability**: Comprehensive logging and monitoring through CloudWatch
6. **Environment Parity**: Identical code deployed across dev, staging, and production with environment-specific configurations

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repository                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  .github/workflows/                                      │   │
│  │  ├── infrastructure-provisioning.yml                     │   │
│  │  └── lambda-deployment.yml                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  infrastructure/                                         │   │
│  │  ├── modules/                                            │   │
│  │  │   ├── api_gateway/                                    │   │
│  │  │   ├── lambda/                                         │   │
│  │  │   ├── dynamodb/                                       │   │
│  │  │   ├── iam/                                            │   │
│  │  │   └── s3/                                             │   │
│  │  └── environments/                                       │   │
│  │      ├── dev/                                            │   │
│  │      ├── staging/                                        │   │
│  │      └── prod/                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  apps/                                                   │   │
│  │  ├── api-handler/                                        │   │
│  │  │   ├── src/                                            │   │
│  │  │   ├── tests/                                          │   │
│  │  │   └── package.json                                    │   │
│  │  └── authorizer/                                         │   │
│  │      ├── src/                                            │   │
│  │      ├── tests/                                          │   │
│  │      └── package.json                                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  data/                                                   │   │
│  │  ├── schemas/                                            │   │
│  │  ├── migrations/                                         │   │
│  │  └── seeds/                                              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ GitHub OIDC Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Account                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  IAM OIDC Provider (GitHub)                              │   │
│  │  ├── Infrastructure Role                                 │   │
│  │  └── Lambda Deployment Role                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  S3 (Terraform State)                                    │   │
│  │  ├── Encryption: KMS                                     │   │
│  │  ├── Versioning: Enabled                                 │   │
│  │  └── Public Access: Blocked                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DynamoDB (State Locking)                                │   │
│  │  └── LockID (Primary Key)                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  API Gateway                                             │   │
│  │  ├── POST /items                                         │   │
│  │  ├── GET /items                                          │   │
│  │  ├── GET /items/{id}                                     │   │
│  │  ├── PUT /items/{id}                                     │   │
│  │  └── DELETE /items/{id}                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Lambda Functions                                        │   │
│  │  ├── api-handler (CRUD operations)                       │   │
│  │  ├── authorizer (Optional JWT validation)                │   │
│  │  └── Execution Role (DynamoDB + CloudWatch)              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DynamoDB (Application Data)                             │   │
│  │  ├── items table                                         │   │
│  │  ├── Primary Key: id (String)                            │   │
│  │  ├── GSI: status-index                                   │   │
│  │  └── TTL: Optional expiration                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CloudWatch                                              │   │
│  │  ├── Lambda Logs                                         │   │
│  │  ├── API Gateway Logs                                    │   │
│  │  └── Terraform Provisioning Logs                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Monorepo Structure

```
serverless-monorepo-aws/
├── .github/
│   └── workflows/
│       ├── infrastructure-provisioning.yml
│       └── lambda-deployment.yml
├── infrastructure/
│   ├── modules/
│   │   ├── api_gateway/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── lambda/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── dynamodb/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── iam/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── s3/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── terraform.tfvars
│   │       └── backend.tf
│   └── global/
│       ├── main.tf (OIDC provider, state bucket, state lock table)
│       └── terraform.tfvars
├── apps/
│   ├── api-handler/
│   │   ├── src/
│   │   │   ├── handlers/
│   │   │   │   ├── create.js
│   │   │   │   ├── read.js
│   │   │   │   ├── update.js
│   │   │   │   ├── delete.js
│   │   │   │   └── list.js
│   │   │   ├── utils/
│   │   │   │   ├── dynamodb.js
│   │   │   │   ├── logger.js
│   │   │   │   └── validators.js
│   │   │   └── index.js
│   │   ├── tests/
│   │   │   ├── unit/
│   │   │   ├── integration/
│   │   │   └── smoke/
│   │   ├── package.json
│   │   └── .eslintrc.json
│   └── authorizer/
│       ├── src/
│       │   └── index.js
│       ├── tests/
│       ├── package.json
│       └── .eslintrc.json
├── data/
│   ├── schemas/
│   │   └── items.json
│   ├── migrations/
│   │   └── 001_create_items_table.js
│   └── seeds/
│       └── dev_seed.js
├── package.json
├── .gitignore
└── README.md
```

### 2. GitHub OIDC Authentication Flow

```
GitHub Actions Workflow
        │
        ├─ Request OIDC Token from GitHub
        │
        ▼
GitHub OIDC Provider
        │
        ├─ Issue JWT Token with claims:
        │  - repository: owner/repo
        │  - ref: refs/heads/main
        │  - actor: github-user
        │
        ▼
AWS IAM OIDC Provider
        │
        ├─ Validate JWT signature
        ├─ Verify token claims
        │
        ▼
Assume IAM Role
        │
        ├─ Infrastructure Role (for terraform)
        ├─ Lambda Deployment Role (for code updates)
        │
        ▼
Temporary AWS Credentials
        │
        └─ Valid for 1 hour
```

### 3. Lambda CRUD Handler Interface

```javascript
// Handler signature for all CRUD operations
async function handler(event, context) {
  // event: {
  //   httpMethod: 'GET|POST|PUT|DELETE',
  //   path: '/items' or '/items/{id}',
  //   body: JSON string (for POST/PUT),
  //   pathParameters: { id: 'item-id' },
  //   queryStringParameters: { limit: '10', offset: '0' }
  // }
  
  // Returns: {
  //   statusCode: 200|201|204|400|404|500,
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON string
  // }
}
```

### 4. DynamoDB Table Schema

```
Table: items (environment-specific: items-dev, items-staging, items-prod)

Primary Key:
  - Partition Key: id (String)
  - Sort Key: None

Attributes:
  - id (String, PK): Unique identifier
  - name (String): Item name
  - description (String): Item description
  - status (String): Item status (active, inactive, archived)
  - createdAt (Number): Unix timestamp
  - updatedAt (Number): Unix timestamp
  - createdBy (String): User who created the item
  - version (Number): Item version for optimistic locking

Global Secondary Indexes:
  - status-index:
    - Partition Key: status
    - Sort Key: createdAt
    - Projection: ALL
    - Throughput: On-demand

Billing Mode: PAY_PER_REQUEST (on-demand)
TTL: Optional (ttl attribute)
Point-in-time Recovery: Enabled
Encryption: AWS managed keys
```

### 5. API Gateway Endpoints

```
Base URL: https://{api-id}.execute-api.{region}.amazonaws.com/{stage}

Endpoints:
  POST   /items              - Create item
  GET    /items              - List all items (with pagination)
  GET    /items/{id}         - Get item by ID
  PUT    /items/{id}         - Update item
  DELETE /items/{id}         - Delete item

Request/Response Format:
  Content-Type: application/json
  CORS: Enabled for all origins (configurable)

Status Codes:
  200: Success (GET, PUT)
  201: Created (POST)
  204: No Content (DELETE)
  400: Bad Request (validation error)
  404: Not Found
  500: Internal Server Error
```

### 6. IAM Roles and Permissions

```
Infrastructure Role (for Terraform):
  - Permissions:
    * s3:GetObject, s3:PutObject (Terraform state)
    * dynamodb:GetItem, dynamodb:PutItem (State locking)
    * apigateway:*
    * lambda:*
    * dynamodb:*
    * iam:CreateRole, iam:PutRolePolicy, iam:AttachRolePolicy
    * logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
  - Trust: GitHub OIDC Provider with conditions:
    * repository: owner/repo
    * ref: refs/heads/main (or specific branches)

Lambda Deployment Role (for Code Updates):
  - Permissions:
    * lambda:UpdateFunctionCode
    * lambda:UpdateFunctionConfiguration
    * s3:GetObject (Lambda code from S3)
    * logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
  - Trust: GitHub OIDC Provider with conditions:
    * repository: owner/repo
    * ref: refs/heads/main

Lambda Execution Role (for Runtime):
  - Permissions:
    * dynamodb:GetItem, dynamodb:PutItem, dynamodb:UpdateItem, dynamodb:DeleteItem, dynamodb:Query, dynamodb:Scan
    * logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
  - Trust: Lambda service (lambda.amazonaws.com)
```

### 7. GitHub Actions Workflows

#### Infrastructure Provisioning Workflow

```yaml
Trigger: Push to infrastructure/ folder on main branch

Steps:
  1. Checkout code
  2. Assume AWS role via OIDC
  3. Configure Terraform backend (S3 + DynamoDB locking)
  4. Run terraform init
  5. Run terraform plan
  6. Display plan output
  7. Require manual approval (for prod)
  8. Run terraform apply
  9. Output infrastructure details
  10. Log to CloudWatch
```

#### Lambda Deployment Workflow

```yaml
Trigger: Push to apps/api-handler/ folder on main branch

Steps:
  1. Checkout code
  2. Install dependencies (npm install)
  3. Run linting (eslint)
  4. Run unit tests (jest)
  5. Run integration tests
  6. Package Lambda function (zip)
  7. Assume AWS role via OIDC
  8. Upload code to S3
  9. Update Lambda function via AWS CLI
  10. Run smoke tests
  11. Log deployment to CloudWatch
```

### 8. CloudWatch Logging Structure

```
Log Groups:
  /aws/lambda/api-handler-{environment}
  /aws/lambda/authorizer-{environment}
  /aws/apigateway/{api-id}
  /aws/terraform/{environment}

Log Format (Structured JSON):
  {
    "timestamp": "2024-01-15T10:30:45.123Z",
    "requestId": "uuid",
    "level": "INFO|WARN|ERROR",
    "service": "api-handler",
    "environment": "dev|staging|prod",
    "message": "Operation completed",
    "duration": 145,
    "statusCode": 200,
    "userId": "user-id",
    "operation": "CREATE|READ|UPDATE|DELETE",
    "itemId": "item-id",
    "error": null
  }
```

## Data Models

### Item Model

```javascript
{
  id: string,                    // UUID
  name: string,                  // Required, max 255 chars
  description: string,           // Optional, max 1000 chars
  status: 'active' | 'inactive' | 'archived',  // Default: 'active'
  createdAt: number,             // Unix timestamp
  updatedAt: number,             // Unix timestamp
  createdBy: string,             // User ID
  version: number,               // For optimistic locking
  ttl?: number                   // Optional TTL (Unix timestamp)
}
```

### Request/Response Models

```javascript
// Create Request
{
  name: string,
  description?: string,
  status?: string
}

// Create Response
{
  id: string,
  name: string,
  description: string,
  status: string,
  createdAt: number,
  updatedAt: number,
  createdBy: string,
  version: number
}

// List Response
{
  items: Item[],
  count: number,
  nextToken?: string
}

// Error Response
{
  error: string,
  message: string,
  requestId: string,
  timestamp: number
}
```

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: CRUD Operations Round Trip
*For any* valid item data, creating an item, retrieving it, updating it, and deleting it should result in the item being removed from the database and all intermediate states being correctly reflected.
**Validates: Requirements 3.1, 3.2, 3.4, 3.5**

### Property 2: Lambda Handler Status Codes
*For any* HTTP request to the Lambda handler, the response status code should match the operation result: 201 for successful creation, 200 for successful read/update, 204 for successful deletion, 400 for invalid input, 404 for not found, and 500 for server errors.
**Validates: Requirements 3.1, 3.2, 3.4, 3.5, 3.6, 3.7, 12.7**

### Property 3: Input Validation Prevents Invalid Operations
*For any* invalid input (missing required fields, invalid data types, malformed JSON), the Lambda handler should reject the request with a 400 status code before attempting any database operation.
**Validates: Requirements 3.6, 3.8, 13.5**

### Property 4: Database Error Handling and Logging
*For any* database error that occurs during a Lambda operation, the handler should return a 500 status code and log the error with stack trace to CloudWatch.
**Validates: Requirements 3.7, 11.2**

### Property 5: Request/Response Logging Completeness
*For any* Lambda invocation, all requests and responses should be logged to CloudWatch with structured format including timestamp, request ID, log level, and operation details.
**Validates: Requirements 3.9, 11.1, 11.3**

### Property 6: Environment-Specific Configuration Isolation
*For any* environment (dev, staging, prod), the configuration should be isolated and not contain hardcoded values in application code, with all environment-specific variables stored in Terraform or GitHub Actions secrets.
**Validates: Requirements 7.1, 7.2, 7.3, 7.4**

### Property 7: Terraform Module Completeness
*For any* Terraform configuration, all required modules (API Gateway, Lambda, DynamoDB, S3, IAM) should be defined and properly referenced in environment-specific configurations.
**Validates: Requirements 2.1, 2.2**

### Property 8: IAM Role Least Privilege Enforcement
*For any* IAM role (Infrastructure, Lambda Deployment, Lambda Execution), the role should have only the minimum permissions required for its function and should not grant unnecessary access to other services or resources.
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7**

### Property 9: GitHub OIDC Token Restriction
*For any* GitHub OIDC token issued, the token should be restricted to specific repository and branch conditions, and should not allow authentication from unauthorized repositories or branches.
**Validates: Requirements 5.3, 5.4**

### Property 10: Terraform State Encryption and Locking
*For any* Terraform state file stored in S3, the file should be encrypted with KMS keys, versioning should be enabled, and concurrent modifications should be prevented through DynamoDB state locking.
**Validates: Requirements 10.1, 10.2, 10.3, 10.5, 10.7**

### Property 11: API Gateway Endpoint Availability
*For any* CRUD operation (create, read, update, delete, list), the corresponding API Gateway endpoint should be available and properly routed to the Lambda handler.
**Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5**

### Property 12: CORS Headers Presence
*For any* API Gateway response, CORS headers should be included to allow cross-origin requests from authorized origins.
**Validates: Requirements 12.8**

### Property 13: DynamoDB Table Schema Consistency
*For any* item stored in DynamoDB, the item should conform to the defined schema with all required attributes (id, name, status, createdAt, updatedAt) and optional attributes properly handled.
**Validates: Requirements 4.1, 4.6**

### Property 14: Workflow Trigger Accuracy
*For any* push to the infrastructure/ folder, the infrastructure provisioning workflow should trigger automatically, and for any push to the apps/api-handler/ folder, the Lambda deployment workflow should trigger automatically.
**Validates: Requirements 8.1, 9.1**

### Property 15: Workflow Quality Gates
*For any* Lambda deployment workflow, the workflow should not deploy code if linting, unit tests, or smoke tests fail, ensuring only validated code reaches production.
**Validates: Requirements 9.2, 9.3, 9.4, 9.9**

### Property 16: No Hardcoded Secrets in Code
*For any* code file in the repository (Terraform, Lambda, configuration), no AWS credentials, API keys, or secrets should be hardcoded or stored in plain text.
**Validates: Requirements 2.8, 13.1, 13.2**

### Property 17: CloudWatch Logging Completeness
*For any* system operation (Lambda invocation, API request, Terraform provisioning), the operation should be logged to CloudWatch with appropriate log level and retention period.
**Validates: Requirements 11.1, 11.3, 11.4, 11.6, 11.7**

### Property 18: HTTPS Enforcement
*For any* API Gateway endpoint, all communications should use HTTPS protocol and HTTP requests should be redirected or rejected.
**Validates: Requirements 13.6**

### Property 19: Terraform Output Completeness
*For any* successful Terraform apply, the infrastructure details (API Gateway URL, Lambda ARN, DynamoDB table name) should be output for use in CI/CD workflows.
**Validates: Requirements 2.7, 8.6**

### Property 20: Production Deployment Approval Gate
*For any* infrastructure change targeting the production environment, the change should require explicit manual approval before terraform apply is executed.
**Validates: Requirements 8.8, 8.9**

## Error Handling

### Lambda Handler Error Scenarios

1. **Invalid Input Validation**
   - Missing required fields → 400 Bad Request
   - Invalid data types → 400 Bad Request
   - Malformed JSON → 400 Bad Request
   - Oversized payload → 413 Payload Too Large

2. **Database Errors**
   - DynamoDB throttling → Retry with exponential backoff, then 500 if exhausted
   - Item not found → 404 Not Found
   - Conditional write failure → 409 Conflict
   - Database connection error → 500 Internal Server Error

3. **Authorization Errors**
   - Missing authentication → 401 Unauthorized
   - Invalid token → 401 Unauthorized
   - Insufficient permissions → 403 Forbidden

4. **System Errors**
   - Lambda timeout → 504 Gateway Timeout
   - Out of memory → 500 Internal Server Error
   - Unhandled exception → 500 Internal Server Error

### Error Response Format

```json
{
  "error": "ValidationError",
  "message": "Missing required field: name",
  "requestId": "uuid",
  "timestamp": 1234567890
}
```

### Terraform Error Handling

1. **State Lock Timeout**
   - Retry acquiring lock with exponential backoff
   - Fail with error message if lock cannot be acquired

2. **Resource Creation Failure**
   - Rollback changes if possible
   - Log error details to CloudWatch
   - Notify user with error message

3. **Backend Configuration Error**
   - Fail fast with clear error message
   - Provide troubleshooting steps

## Testing Strategy

### Unit Testing

**Lambda CRUD Operations**:
- Test each CRUD operation (create, read, update, delete, list) with valid inputs
- Test input validation for each operation
- Test error handling for database errors
- Test logging output format and content
- Target: 80% code coverage minimum

**Test Framework**: Jest
**Test Location**: `apps/api-handler/tests/unit/`

**Example Unit Tests**:
```javascript
// Test: Create operation with valid input
describe('Create Handler', () => {
  it('should create item and return 201', async () => {
    const event = { body: JSON.stringify({ name: 'Test Item' }) };
    const result = await createHandler(event);
    expect(result.statusCode).toBe(201);
    expect(JSON.parse(result.body).id).toBeDefined();
  });
});

// Test: Input validation
describe('Input Validation', () => {
  it('should reject missing required fields', async () => {
    const event = { body: JSON.stringify({}) };
    const result = await createHandler(event);
    expect(result.statusCode).toBe(400);
  });
});
```

### Integration Testing

**API Gateway + Lambda Integration**:
- Test end-to-end CRUD flows through API Gateway
- Test request/response transformation
- Test error propagation
- Test CORS headers

**Test Framework**: Jest with AWS SDK mocking
**Test Location**: `apps/api-handler/tests/integration/`

### Smoke Testing

**Post-Deployment Validation**:
- Verify API Gateway endpoint is accessible
- Verify Lambda function is deployed and callable
- Verify DynamoDB table is accessible
- Verify CloudWatch logs are being written
- Verify CORS headers are present

**Test Framework**: Node.js HTTP client
**Test Location**: `apps/api-handler/tests/smoke/`

### Property-Based Testing

**Property 1: CRUD Round Trip**
- **Feature: serverless-monorepo-aws, Property 1: CRUD Operations Round Trip**
- Generate random item data
- Create item, retrieve it, update it, delete it
- Verify final state matches expected behavior

**Property 2: Lambda Status Codes**
- **Feature: serverless-monorepo-aws, Property 2: Lambda Handler Status Codes**
- Generate various request types (valid, invalid, edge cases)
- Verify status code matches operation result

**Property 3: Input Validation**
- **Feature: serverless-monorepo-aws, Property 3: Input Validation Prevents Invalid Operations**
- Generate invalid inputs (missing fields, wrong types, malformed JSON)
- Verify all invalid inputs are rejected with 400 status

**Property 4: Error Handling**
- **Feature: serverless-monorepo-aws, Property 4: Database Error Handling and Logging**
- Simulate database errors
- Verify 500 status code and error logging

**Property 5: Logging Completeness**
- **Feature: serverless-monorepo-aws, Property 5: Request/Response Logging Completeness**
- Verify all requests/responses are logged with required fields

**Property 6: Environment Configuration**
- **Feature: serverless-monorepo-aws, Property 6: Environment-Specific Configuration Isolation**
- Verify no hardcoded values in code for different environments

**Property 7: Terraform Modules**
- **Feature: serverless-monorepo-aws, Property 7: Terraform Module Completeness**
- Verify all required modules are defined and can be parsed

**Property 8: IAM Least Privilege**
- **Feature: serverless-monorepo-aws, Property 8: IAM Role Least Privilege Enforcement**
- Verify roles have only required permissions

**Property 9: OIDC Token Restriction**
- **Feature: serverless-monorepo-aws, Property 9: GitHub OIDC Token Restriction**
- Verify tokens are restricted to specific repository/branch

**Property 10: State Encryption**
- **Feature: serverless-monorepo-aws, Property 10: Terraform State Encryption and Locking**
- Verify state files are encrypted and locking is configured

**Property 11: API Endpoints**
- **Feature: serverless-monorepo-aws, Property 11: API Gateway Endpoint Availability**
- Verify all CRUD endpoints are available and routed correctly

**Property 12: CORS Headers**
- **Feature: serverless-monorepo-aws, Property 12: CORS Headers Presence**
- Verify CORS headers are present in all responses

**Property 13: DynamoDB Schema**
- **Feature: serverless-monorepo-aws, Property 13: DynamoDB Table Schema Consistency**
- Verify items conform to defined schema

**Property 14: Workflow Triggers**
- **Feature: serverless-monorepo-aws, Property 14: Workflow Trigger Accuracy**
- Verify workflows trigger on correct folder changes

**Property 15: Quality Gates**
- **Feature: serverless-monorepo-aws, Property 15: Workflow Quality Gates**
- Verify deployment is blocked if tests fail

**Property 16: No Hardcoded Secrets**
- **Feature: serverless-monorepo-aws, Property 16: No Hardcoded Secrets in Code**
- Scan code for hardcoded credentials

**Property 17: CloudWatch Logging**
- **Feature: serverless-monorepo-aws, Property 17: CloudWatch Logging Completeness**
- Verify all operations are logged to CloudWatch

**Property 18: HTTPS Enforcement**
- **Feature: serverless-monorepo-aws, Property 18: HTTPS Enforcement**
- Verify HTTPS is enforced for all API communications

**Property 19: Terraform Outputs**
- **Feature: serverless-monorepo-aws, Property 19: Terraform Output Completeness**
- Verify infrastructure details are output after apply

**Property 20: Production Approval**
- **Feature: serverless-monorepo-aws, Property 20: Production Deployment Approval Gate**
- Verify production changes require approval

### Terraform Testing

**Terraform Validation**:
- Run `terraform validate` to check syntax
- Run `terraform plan` to verify resource creation
- Use `terraform test` for module testing (Terraform 1.6+)

**Test Location**: `infrastructure/tests/`

### CI/CD Workflow Testing

**Workflow Validation**:
- Verify workflows trigger on correct events
- Verify workflow steps execute in correct order
- Verify approval gates are enforced
- Verify error notifications are sent

**Test Framework**: GitHub Actions workflow testing
**Test Location**: `.github/workflows/`

### Test Execution in CI/CD

**Lambda Deployment Workflow**:
1. Run linting (eslint)
2. Run unit tests (jest)
3. Run integration tests (jest)
4. Package Lambda function
5. Deploy to Lambda
6. Run smoke tests
7. Log results to CloudWatch

**Infrastructure Provisioning Workflow**:
1. Validate Terraform syntax
2. Run terraform plan
3. Require manual approval (prod only)
4. Run terraform apply
5. Output infrastructure details
6. Log to CloudWatch

