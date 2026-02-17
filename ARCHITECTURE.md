# Architecture Documentation

## System Overview

The Serverless Monorepo AWS system is a production-ready serverless architecture that combines Infrastructure as Code (Terraform), Lambda functions, DynamoDB, and GitHub Actions CI/CD automation. The system emphasizes security through OIDC-based authentication, least-privilege IAM roles, and encrypted state management.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repository                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  .github/workflows/                                      │   │
│  │  ├── infrastructure-provisioning.yml                     │   │
│  │  └── lambda-deployment.yml                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  infrastructure/ (Terraform IaC)                         │   │
│  │  ├── modules/ (Reusable components)                      │   │
│  │  ├── environments/ (dev, staging, prod)                  │   │
│  │  └── global/ (OIDC, state backend)                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  apps/ (Lambda applications)                             │   │
│  │  ├── api-handler/ (CRUD operations)                      │   │
│  │  └── authorizer/ (Optional JWT validation)               │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  data/ (Data layer)                                      │   │
│  │  ├── schemas/ (DynamoDB table schemas)                   │   │
│  │  ├── migrations/ (Database migrations)                   │   │
│  │  └── seeds/ (Seed data)                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ GitHub OIDC Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Account                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  IAM OIDC Provider (GitHub)                              │   │
│  │  ├── Infrastructure Role (Terraform)                     │   │
│  │  └── Lambda Deployment Role (Code updates)               │   │
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
│  │  CloudWatch                                              │   │
│  │  ├── Lambda Logs                                         │   │
│  │  ├── API Gateway Logs                                    │   │
│  │  └── Terraform Provisioning Logs                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### 1. GitHub Repository

**Purpose**: Version control and CI/CD automation

**Components**:
- **Workflows**: GitHub Actions workflows for infrastructure and Lambda deployment
- **Infrastructure Code**: Terraform modules and configurations
- **Application Code**: Lambda function source code
- **Data Layer**: DynamoDB schemas, migrations, and seed data

**Key Features**:
- OIDC-based authentication (no hardcoded credentials)
- Automated testing and validation
- Environment-specific deployments
- Approval gates for production

### 2. GitHub OIDC Provider

**Purpose**: Secure authentication for GitHub Actions to AWS

**How It Works**:
1. GitHub Actions workflow requests OIDC token from GitHub
2. GitHub issues JWT token with claims (repository, branch, actor)
3. GitHub Actions exchanges token for temporary AWS credentials
4. AWS validates token signature and claims
5. Temporary credentials are used for AWS API calls

**Security Benefits**:
- No long-lived AWS credentials stored in GitHub
- Tokens are short-lived (1 hour)
- Tokens are restricted to specific repository and branch
- Automatic token rotation

**Configuration**:
- Created by `infrastructure/bootstrap/main.tf`
- Restricted to specific GitHub organization and repository
- Restricted to specific branch (default: main)

### 3. IAM Roles

**Infrastructure Role**
- **Purpose**: Allows GitHub Actions to deploy infrastructure via Terraform
- **Permissions**: S3, DynamoDB, API Gateway, Lambda, IAM, CloudWatch, KMS
- **Trust**: GitHub OIDC provider with repository and branch conditions
- **Usage**: Infrastructure provisioning workflow

**Lambda Deployment Role**
- **Purpose**: Allows GitHub Actions to update Lambda code
- **Permissions**: S3 (get/put), Lambda (update code), CloudWatch Logs
- **Trust**: GitHub OIDC provider with repository and branch conditions
- **Usage**: Lambda deployment workflow

**Lambda Execution Role**
- **Purpose**: Allows Lambda functions to access DynamoDB and CloudWatch
- **Permissions**: DynamoDB (CRUD), CloudWatch Logs
- **Trust**: Lambda service only
- **Usage**: Runtime permissions for Lambda functions

### 4. API Gateway

**Purpose**: REST API endpoints for CRUD operations

**Endpoints**:
- `POST /items` - Create item
- `GET /items` - List items (with pagination)
- `GET /items/{id}` - Get item by ID
- `PUT /items/{id}` - Update item
- `DELETE /items/{id}` - Delete item

**Features**:
- CORS enabled for cross-origin requests
- Request/response validation
- CloudWatch logging for all requests
- Throttling and rate limiting
- HTTPS enforcement

**Integration**:
- Integrated with Lambda function (api-handler)
- Transforms HTTP requests to Lambda events
- Transforms Lambda responses to HTTP responses

### 5. Lambda Functions

**api-handler**
- **Purpose**: Implements CRUD operations
- **Triggers**: API Gateway requests
- **Environment Variables**: DynamoDB table name, environment
- **Execution Role**: Lambda Execution Role
- **Logging**: CloudWatch Logs with structured format
- **Error Handling**: Returns appropriate HTTP status codes

**authorizer** (Optional)
- **Purpose**: JWT token validation
- **Triggers**: API Gateway authorization requests
- **Returns**: IAM policy for authorized/unauthorized requests

### 6. DynamoDB

**Application Data Table (items)**
- **Primary Key**: id (String)
- **Attributes**: name, description, status, createdAt, updatedAt, createdBy, version, ttl
- **GSI**: status-index (partition key: status, sort key: createdAt)
- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Encryption**: AWS managed keys
- **PITR**: Enabled for point-in-time recovery
- **TTL**: Supported for automatic expiration

**State Locking Table**
- **Primary Key**: LockID (String)
- **Purpose**: Prevents concurrent Terraform state modifications
- **Managed By**: Terraform global module

### 7. S3 Buckets

**Terraform State Bucket**
- **Purpose**: Stores Terraform state files
- **Encryption**: KMS encryption enabled
- **Versioning**: Enabled for state history
- **Public Access**: Blocked
- **Access Logging**: Enabled for audit trail
- **Lifecycle Policies**: Automatic cleanup of old versions

**Lambda Code Bucket**
- **Purpose**: Stores Lambda function code packages
- **Encryption**: Server-side encryption enabled
- **Versioning**: Enabled
- **Lifecycle Policies**: Automatic cleanup of old versions

### 8. CloudWatch

**Log Groups**:
- `/aws/lambda/api-handler-{environment}` - Lambda function logs
- `/aws/lambda/authorizer-{environment}` - Authorizer logs
- `/aws/apigateway/{api-id}` - API Gateway logs
- `/aws/terraform/{environment}` - Terraform provisioning logs

**Log Format** (Structured JSON):
```json
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

**Retention**: 30 days (configurable per environment)

## Data Flow Diagrams

### Request Flow

```
Client Request
    │
    ▼
API Gateway
    │ (Validates request)
    ▼
Lambda Handler (api-handler)
    │ (Routes to CRUD handler)
    ├─ CREATE ─→ DynamoDB Put
    ├─ READ   ─→ DynamoDB Get
    ├─ UPDATE ─→ DynamoDB Update
    ├─ DELETE ─→ DynamoDB Delete
    └─ LIST   ─→ DynamoDB Scan
    │
    ├─ Logs to CloudWatch
    │
    ▼
API Gateway Response
    │
    ▼
Client Response
```

### Deployment Flow

```
Developer Push to GitHub
    │
    ▼
GitHub Actions Workflow Triggered
    │
    ├─ Infrastructure Changes
    │  ├─ Checkout code
    │  ├─ Request OIDC token
    │  ├─ Assume Infrastructure Role
    │  ├─ Terraform init/plan/apply
    │  └─ Log to CloudWatch
    │
    └─ Lambda Code Changes
       ├─ Checkout code
       ├─ Run linting
       ├─ Run tests
       ├─ Package code
       ├─ Request OIDC token
       ├─ Assume Lambda Deployment Role
       ├─ Upload to S3
       ├─ Update Lambda function
       ├─ Run smoke tests
       └─ Log to CloudWatch
```

### State Management Flow

```
Terraform Command
    │
    ▼
Acquire State Lock
    │ (DynamoDB)
    ▼
Read State from S3
    │ (Encrypted with KMS)
    ▼
Execute Terraform Operation
    │
    ▼
Write State to S3
    │ (Encrypted with KMS)
    ▼
Release State Lock
    │ (DynamoDB)
    ▼
Operation Complete
```

## Security Architecture

### Authentication & Authorization

**GitHub OIDC Flow**:
1. GitHub Actions requests OIDC token
2. GitHub issues JWT with claims
3. AWS validates token signature
4. AWS validates token claims (repository, branch)
5. AWS issues temporary credentials
6. Temporary credentials used for AWS API calls

**IAM Role Trust Relationships**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### Data Encryption

**In Transit**:
- HTTPS for all API communications
- TLS 1.2+ for all connections

**At Rest**:
- S3 state bucket: KMS encryption
- DynamoDB: AWS managed encryption
- Lambda environment variables: Encrypted by default

### Least Privilege Access

**Infrastructure Role**:
- Only permissions needed for Terraform
- Cannot delete production resources without approval
- Restricted to specific repository and branch

**Lambda Deployment Role**:
- Only permissions to update Lambda code
- Cannot modify infrastructure or IAM roles
- Restricted to specific repository and branch

**Lambda Execution Role**:
- Only permissions to access DynamoDB and CloudWatch
- Cannot access other AWS services
- Scoped to specific DynamoDB table

### Audit & Compliance

**CloudWatch Logging**:
- All Lambda invocations logged
- All API Gateway requests logged
- All Terraform operations logged
- Structured JSON format for easy parsing
- 30-day retention (configurable)

**S3 Access Logging**:
- All state file access logged
- Tracks who accessed state and when
- Enables audit trail for compliance

**Terraform State Versioning**:
- All state changes tracked
- Can rollback to previous state
- Enables disaster recovery

## Environment Isolation

### Dev Environment
- Automatic deployment on push
- No approval gates
- Shorter log retention (7 days)
- Lower Lambda memory allocation
- On-demand DynamoDB billing

### Staging Environment
- Automatic deployment on push
- Manual approval for infrastructure changes
- Standard log retention (30 days)
- Standard Lambda memory allocation
- On-demand DynamoDB billing

### Production Environment
- Manual approval required for all changes
- Approval gates in GitHub Actions
- Extended log retention (90 days)
- Higher Lambda memory allocation
- Reserved capacity for DynamoDB (optional)

## Scalability Considerations

### Lambda
- Automatic scaling based on request volume
- Concurrent execution limits per environment
- Reserved concurrency for production
- Timeout: 30 seconds (configurable)

### DynamoDB
- On-demand billing mode (auto-scales)
- GSI for efficient queries
- TTL for automatic cleanup
- Point-in-time recovery enabled

### API Gateway
- Throttling: 10,000 requests/second (default)
- Burst: 5,000 requests/second
- Caching: Optional for GET requests
- CloudFront integration: Optional for global distribution

## Disaster Recovery

### Backup Strategy
- Terraform state versioning in S3
- DynamoDB point-in-time recovery
- CloudWatch logs retention
- Automated state backups before destruction

### Recovery Procedures
1. **Lambda Function Failure**: Redeploy from GitHub Actions
2. **DynamoDB Data Loss**: Restore from PITR
3. **Terraform State Corruption**: Restore from S3 version history
4. **Complete Environment Loss**: Redeploy from Terraform code

### RTO/RPO Targets
- **RTO** (Recovery Time Objective): < 15 minutes
- **RPO** (Recovery Point Objective): < 1 hour

## Performance Optimization

### Lambda
- Provisioned concurrency for production
- Memory optimization (128MB - 10GB)
- Code optimization for cold starts
- Connection pooling for DynamoDB

### DynamoDB
- GSI for efficient queries
- Partition key design for even distribution
- TTL for automatic cleanup
- On-demand billing for variable workloads

### API Gateway
- Request/response caching
- CloudFront integration for global distribution
- Compression for response payloads
- Connection keep-alive

## Monitoring & Alerting

### CloudWatch Metrics
- Lambda invocations and duration
- Lambda errors and throttling
- DynamoDB consumed capacity
- API Gateway request count and latency

### CloudWatch Alarms
- Lambda error rate > 5%
- Lambda duration > 10 seconds
- DynamoDB throttling
- API Gateway 5xx errors

### Dashboards
- Real-time system health
- Request/response metrics
- Error tracking
- Cost analysis

## Cost Optimization

### Lambda
- On-demand pricing (pay per invocation)
- Free tier: 1 million invocations/month
- Estimated cost: $0.20 per million invocations

### DynamoDB
- On-demand billing (pay per request)
- Free tier: 25 GB storage, 25 RCU, 25 WCU
- Estimated cost: $1.25 per million write units

### API Gateway
- $3.50 per million API calls
- Free tier: 1 million API calls/month

### S3
- $0.023 per GB stored
- $0.0004 per 10,000 PUT requests
- Free tier: 5 GB storage

### Total Estimated Monthly Cost
- Development: $10-20/month
- Staging: $20-50/month
- Production: $50-200/month (depending on traffic)

## Related Documentation

- [README.md](./README.md) - Project overview and quick start
- [CONFIGURATION.md](./CONFIGURATION.md) - Environment variables and configuration
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Production deployment guide
- [infrastructure/bootstrap/README.md](./infrastructure/bootstrap/README.md) - OIDC setup
- [infrastructure/scripts/README.md](./infrastructure/scripts/README.md) - Infrastructure scripts
- [data/README.md](./data/README.md) - Data layer documentation
