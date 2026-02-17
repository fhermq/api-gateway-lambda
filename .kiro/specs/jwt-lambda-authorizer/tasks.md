# Implementation Plan: JWT Lambda Authorizer

## Overview

This implementation plan breaks down the JWT Lambda Authorizer feature into discrete, incremental coding tasks. The approach follows a layered architecture: first establishing core utilities and types, then implementing the three main Lambda handlers (Token Endpoint, Lambda Authorizer, Client Manager), followed by integration and comprehensive testing.

Each task builds on previous work, with property-based tests integrated throughout to catch correctness issues early. Optional testing sub-tasks (marked with `*`) can be skipped for faster MVP delivery but are recommended for production quality.

## Tasks

- [ ] 1. Set up project structure and core utilities
  - Create TypeScript project structure with Lambda handler directories
  - Set up build configuration (esbuild for Lambda bundling)
  - Create shared utilities module for JWT operations (sign, verify, decode)
  - Create shared utilities for Secrets Manager access with caching
  - Create shared utilities for DynamoDB operations
  - Create shared types and interfaces for JWT claims, tokens, and responses
  - Set up environment variable configuration loader
  - _Requirements: 1.1, 2.1, 3.1, 3.2, 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 2. Implement JWT utilities and secret management
  - [ ] 2.1 Create JWT signing and verification functions
    - Implement `signToken(payload, secret)` function using HS256
    - Implement `verifyToken(token, secret)` function with error handling
    - Implement `decodeToken(token)` function for claim extraction
    - _Requirements: 1.1, 4.1, 4.2, 4.3, 4.4_
  
  - [ ]* 2.2 Write property test for JWT round-trip
    - **Property 1: Token Generation Includes Required Claims**
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
  
  - [ ] 2.3 Create Secrets Manager integration with caching
    - Implement `getJWTSecret()` function that retrieves from Secrets Manager
    - Implement in-memory caching for secrets during Lambda execution
    - Implement error handling for Secrets Manager unavailability
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6_
  
  - [ ]* 2.4 Write property test for secret caching
    - **Property 7: Authorization Decision Caching**
    - **Validates: Requirements 3.3**

- [ ] 3. Implement DynamoDB client management
  - [ ] 3.1 Create DynamoDB table schema and client operations
    - Define DynamoDB table structure for clients (client_id, client_secret_hash, metadata)
    - Implement `createClient(name, description)` function
    - Implement `getClient(clientId)` function
    - Implement `updateClient(clientId, updates)` function
    - Implement `deleteClient(clientId)` function
    - Implement `listClients()` function with pagination
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_
  
  - [ ]* 3.2 Write property tests for client management
    - **Property 10: Client Creation Generates Unique Credentials**
    - **Property 11: Created Clients Are Retrievable**
    - **Validates: Requirements 11.1, 11.2, 11.4**

- [ ] 4. Implement Token Endpoint Lambda handler
  - [ ] 4.1 Create token generation logic
    - Implement `generateAccessToken(clientId, expirationSeconds)` function
    - Include all required claims (sub, iss, aud, exp, iat)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ]* 4.2 Write property test for token generation
    - **Property 2: Token Expiration Matches Configuration**
    - **Validates: Requirements 1.2**
  
  - [ ] 4.3 Implement client credentials grant flow
    - Implement request validation for client_credentials grant type
    - Implement client credential verification against DynamoDB
    - Implement token issuance response formatting
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_
  
  - [ ]* 4.4 Write property tests for client credentials flow
    - **Property 3: Invalid Credentials Return 401**
    - **Property 12: Valid Client Credentials Produce Token**
    - **Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6**
  
  - [ ] 4.5 Implement error handling and logging
    - Implement 401 responses for invalid credentials
    - Implement 400 responses for malformed requests
    - Implement 500 responses for server errors
    - Implement structured logging for all operations
    - _Requirements: 1.6, 6.3, 6.4, 6.5_

- [ ] 5. Checkpoint - Ensure all Token Endpoint tests pass
  - Ensure all unit and property tests pass for Token Endpoint
  - Verify error handling works correctly
  - Ask the user if questions arise

- [ ] 6. Implement Lambda Authorizer
  - [ ] 6.1 Create Bearer token extraction and validation
    - Implement `extractBearerToken(authorizationToken)` function
    - Implement Bearer format validation
    - Implement error handling for malformed headers
    - _Requirements: 2.1, 2.5, 9.2, 9.3_
  
  - [ ]* 6.2 Write property tests for Bearer token handling
    - **Property 6: Malformed Authorization Header Denied**
    - **Validates: Requirements 2.1, 2.5, 9.2, 9.3**
  
  - [ ] 6.3 Implement token validation logic
    - Implement signature verification using JWT secret
    - Implement expiration time validation
    - Implement issuer claim validation
    - Implement audience claim validation
    - Implement subject claim extraction
    - _Requirements: 2.2, 2.3, 2.6, 2.7, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [ ]* 6.4 Write property tests for token validation
    - **Property 4: Valid Token Produces Allow Policy**
    - **Property 5: Invalid Token Produces Deny Policy**
    - **Property 9: Subject Claim Extraction**
    - **Validates: Requirements 2.2, 2.3, 2.6, 2.7, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**
  
  - [ ] 6.5 Implement authorization caching
    - Implement cache key generation (SHA256 hash of token)
    - Implement cache storage and retrieval
    - Implement cache TTL expiration
    - Implement cache isolation per invocation
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  
  - [ ]* 6.6 Write property tests for caching
    - **Property 7: Authorization Decision Caching**
    - **Property 8: Cache Expiration Triggers Re-validation**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.6**
  
  - [ ] 6.7 Implement IAM policy generation
    - Implement `buildAllowPolicy(principalId, methodArn, context)` function
    - Implement `buildDenyPolicy(principalId, methodArn)` function
    - Include authorization context in Allow policy
    - _Requirements: 2.2, 2.3, 10.2, 10.3, 10.4, 10.5_
  
  - [ ] 6.8 Implement error handling and logging
    - Implement 401 responses for all error conditions
    - Implement structured logging for validation failures
    - Implement logging for successful validations
    - _Requirements: 2.4, 6.1, 6.2, 6.3, 6.6_

- [ ] 7. Checkpoint - Ensure all Lambda Authorizer tests pass
  - Ensure all unit and property tests pass for Lambda Authorizer
  - Verify caching works correctly
  - Verify error handling works correctly
  - Ask the user if questions arise

- [ ] 8. Implement Client Manager Lambda handler
  - [ ] 8.1 Create client creation endpoint
    - Implement request validation for create action
    - Implement unique client_id and client_secret generation
    - Implement client storage in DynamoDB
    - Implement response with credentials
    - _Requirements: 11.1, 11.2, 11.3_
  
  - [ ]* 8.2 Write property tests for client creation
    - **Property 10: Client Creation Generates Unique Credentials**
    - **Property 11: Created Clients Are Retrievable**
    - **Validates: Requirements 11.1, 11.2, 11.3**
  
  - [ ] 8.3 Create client retrieval endpoint
    - Implement get action to retrieve client details
    - Implement response formatting with all required fields
    - _Requirements: 11.4_
  
  - [ ] 8.4 Create client update endpoint
    - Implement update action for client metadata
    - Implement persistence of updates to DynamoDB
    - _Requirements: 11.5_
  
  - [ ] 8.5 Create client deletion endpoint
    - Implement delete action to remove client from DynamoDB
    - Implement soft delete flag to prevent future token requests
    - _Requirements: 11.6, 11.7_
  
  - [ ] 8.6 Implement error handling and logging
    - Implement 403 responses for unauthorized access
    - Implement 404 responses for missing clients
    - Implement 400 responses for invalid input
    - Implement structured logging
    - _Requirements: 6.1, 6.2, 6.5, 6.6_

- [ ] 9. Checkpoint - Ensure all Client Manager tests pass
  - Ensure all unit and property tests pass for Client Manager
  - Verify CRUD operations work correctly
  - Ask the user if questions arise

- [ ] 10. Implement API Gateway integration
  - [ ] 10.1 Configure Lambda Authorizer in API Gateway
    - Set up Lambda Authorizer as authorizer for all routes
    - Configure authorizer caching settings
    - Configure identity source (Authorization header)
    - _Requirements: 2.1, 10.1_
  
  - [ ] 10.2 Configure Token Endpoint route
    - Create POST /auth/token route
    - Attach Token Endpoint Lambda handler
    - Configure CORS headers
    - _Requirements: 1.1_
  
  - [ ] 10.3 Configure Client Manager routes
    - Create POST /admin/clients route (create)
    - Create GET /admin/clients/{clientId} route (get)
    - Create PUT /admin/clients/{clientId} route (update)
    - Create DELETE /admin/clients/{clientId} route (delete)
    - Attach Client Manager Lambda handler
    - Configure CORS headers
    - _Requirements: 11.1, 11.4, 11.5, 11.6_
  
  - [ ] 10.4 Configure protected routes
    - Ensure all application routes use Lambda Authorizer
    - Verify authorization context is passed to handlers
    - _Requirements: 10.1, 10.3, 10.4, 10.5_

- [ ] 11. Implement multi-environment configuration
  - [ ] 11.1 Create environment-specific configuration
    - Create config files for dev, staging, prod environments
    - Configure JWT_SECRET_NAME per environment
    - Configure JWT_ISSUER per environment
    - Configure JWT_AUDIENCE per environment
    - Configure JWT_EXPIRATION_SECONDS per environment
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 11.2 Create Secrets Manager secrets per environment
    - Create jwt-secret-dev secret
    - Create jwt-secret-staging secret
    - Create jwt-secret-prod secret
    - _Requirements: 3.1, 3.2, 3.4_
  
  - [ ] 11.3 Create DynamoDB tables per environment
    - Create {environment}-jwt-clients table
    - Configure appropriate billing mode
    - _Requirements: 11.1, 11.2_

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Ensure all unit tests pass
  - Ensure all property-based tests pass (minimum 100 iterations each)
  - Verify error handling across all components
  - Verify logging is working correctly
  - Ask the user if questions arise

- [ ] 13. Create deployment documentation
  - [ ] 13.1 Document deployment procedure
    - Document prerequisites (AWS credentials, permissions)
    - Document environment setup steps
    - Document secret creation steps
    - Document table creation steps
    - Document Lambda deployment steps
    - Document API Gateway configuration steps
  
  - [ ] 13.2 Document operational procedures
    - Document secret rotation procedure
    - Document client management procedures
    - Document troubleshooting guide
    - Document monitoring and alerting setup

## Infrastructure as Code (AWS SAM)

This JWT Lambda Authorizer feature will be deployed using **AWS SAM (Serverless Application Model)** for the following reasons:

1. **Simplicity**: SAM is designed specifically for serverless applications with Lambda + API Gateway + DynamoDB
2. **Speed**: Faster setup and deployment compared to Terraform (2-4 hours vs 4-8 hours)
3. **Local Testing**: Built-in `sam local start-api` for testing without AWS deployment
4. **AWS-Native**: Native AWS tool with excellent documentation and community support
5. **Integration**: Seamless integration with existing serverless-monorepo-aws infrastructure

### SAM Template Structure

The JWT Lambda Authorizer will use a `template.yaml` file that defines:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]

Resources:
  # Secrets Manager Secret
  JWTSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Sub 'jwt-secret-${Environment}'
      SecretString: !Sub |
        {
          "secret": "${JWTSecretValue}",
          "algorithm": "HS256"
        }

  # DynamoDB Table for Clients
  ClientsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub '${Environment}-jwt-clients'
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: client_id
          AttributeType: S
      KeySchema:
        - AttributeName: client_id
          KeyType: HASH

  # Lambda Execution Role
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: SecretsManagerAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                Resource: !GetAtt JWTSecret.Arn
        - PolicyName: DynamoDBAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:GetItem
                  - dynamodb:PutItem
                  - dynamodb:UpdateItem
                  - dynamodb:DeleteItem
                  - dynamodb:Query
                  - dynamodb:Scan
                Resource: !GetAtt ClientsTable.Arn

  # Token Endpoint Lambda
  TokenEndpointFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub '${Environment}-jwt-token-endpoint'
      CodeUri: src/handlers/token-endpoint/
      Handler: index.handler
      Runtime: nodejs18.x
      Role: !GetAtt LambdaExecutionRole.Arn
      Environment:
        Variables:
          JWT_SECRET_NAME: !Ref JWTSecret
          CLIENTS_TABLE_NAME: !Ref ClientsTable
          ENVIRONMENT: !Ref Environment

  # Lambda Authorizer Function
  AuthorizerFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub '${Environment}-jwt-authorizer'
      CodeUri: src/handlers/authorizer/
      Handler: index.handler
      Runtime: nodejs18.x
      Role: !GetAtt LambdaExecutionRole.Arn
      Environment:
        Variables:
          JWT_SECRET_NAME: !Ref JWTSecret
          ENVIRONMENT: !Ref Environment

  # Client Manager Lambda
  ClientManagerFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub '${Environment}-jwt-client-manager'
      CodeUri: src/handlers/client-manager/
      Handler: index.handler
      Runtime: nodejs18.x
      Role: !GetAtt LambdaExecutionRole.Arn
      Environment:
        Variables:
          CLIENTS_TABLE_NAME: !Ref ClientsTable
          ENVIRONMENT: !Ref Environment

  # API Gateway
  ApiGateway:
    Type: AWS::Serverless::Api
    Properties:
      StageName: !Ref Environment
      Auth:
        DefaultAuthorizer: JWTAuthorizer
        Authorizers:
          JWTAuthorizer:
            FunctionArn: !GetAtt AuthorizerFunction.Arn
            Identity:
              ReauthorizeEveryInSeconds: 300

  # Token Endpoint Route (no auth required)
  TokenEndpointRoute:
    Type: AWS::Serverless::Function
    Properties:
      Events:
        TokenEndpoint:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /auth/token
            Method: POST
            Auth:
              ApiKeyRequired: false

  # Client Manager Routes
  ClientManagerRoute:
    Type: AWS::Serverless::Function
    Properties:
      Events:
        CreateClient:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /admin/clients
            Method: POST
        GetClient:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /admin/clients/{clientId}
            Method: GET
        UpdateClient:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /admin/clients/{clientId}
            Method: PUT
        DeleteClient:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /admin/clients/{clientId}
            Method: DELETE

Outputs:
  ApiEndpoint:
    Description: API Gateway endpoint URL
    Value: !Sub 'https://${ApiGateway}.execute-api.${AWS::Region}.amazonaws.com/${Environment}'
  
  ClientsTableName:
    Description: DynamoDB Clients table name
    Value: !Ref ClientsTable
  
  JWTSecretName:
    Description: Secrets Manager secret name for JWT
    Value: !Ref JWTSecret
```

### SAM Deployment Commands

```bash
# Initialize SAM project
sam init --runtime nodejs18.x --name jwt-lambda-authorizer

# Build the project
sam build

# Deploy to dev environment
sam deploy --parameter-overrides Environment=dev

# Deploy to staging environment
sam deploy --parameter-overrides Environment=staging

# Deploy to prod environment
sam deploy --parameter-overrides Environment=prod

# Local testing
sam local start-api

# Invoke Lambda locally
sam local invoke TokenEndpointFunction -e events/token-request.json
```

### SAM Project Structure

```
jwt-lambda-authorizer/
├── template.yaml                 # SAM template (infrastructure)
├── parameters-dev.json           # Dev environment parameters
├── parameters-staging.json       # Staging environment parameters
├── parameters-prod.json          # Prod environment parameters
├── src/
│   ├── handlers/
│   │   ├── token-endpoint/
│   │   │   ├── index.ts
│   │   │   └── package.json
│   │   ├── authorizer/
│   │   │   ├── index.ts
│   │   │   └── package.json
│   │   └── client-manager/
│   │       ├── index.ts
│   │       └── package.json
│   ├── utils/
│   │   ├── jwt.ts               # JWT signing/verification
│   │   ├── secrets.ts           # Secrets Manager integration
│   │   ├── dynamodb.ts          # DynamoDB operations
│   │   ├── logger.ts            # Structured logging
│   │   └── types.ts             # TypeScript types
│   └── tests/
│       ├── unit/
│       ├── integration/
│       └── properties/
├── events/
│   ├── token-request.json
│   ├── auth-request.json
│   └── client-request.json
├── package.json
├── tsconfig.json
├── jest.config.js
└── README.md
```

### Integration with serverless-monorepo-aws

The JWT Lambda Authorizer can be deployed as a separate SAM application or integrated into the existing serverless-monorepo-aws infrastructure:

**Option 1: Separate SAM Application** (Recommended)
- Deploy JWT Lambda Authorizer as standalone SAM application
- Integrate with existing API Gateway from serverless-monorepo-aws
- Allows independent versioning and deployment

**Option 2: Integrated into Existing Terraform**
- Add JWT Lambda functions to existing Terraform modules
- Reuse existing API Gateway and DynamoDB infrastructure
- Requires updating existing Terraform code

We recommend **Option 1** for modularity and reusability.

## Notes

- Tasks marked with `*` are optional testing sub-tasks and can be skipped for faster MVP delivery
- Core implementation tasks (without `*`) must be completed for production quality
- Each property-based test should run minimum 100 iterations to ensure comprehensive coverage
- All code should follow AWS Lambda best practices for performance and cost
- All secrets and sensitive data must be stored in Secrets Manager, never in code or environment variables
- All DynamoDB operations should use batch operations where possible for performance
- All Lambda handlers should implement proper error handling and logging
- All API endpoints should be protected by the Lambda Authorizer except the Token Endpoint
- **Infrastructure deployment via AWS SAM** - Use `template.yaml` for all AWS resources
- **Local testing** - Use `sam local start-api` for development and testing
- **Environment-specific parameters** - Use separate parameter files for dev, staging, prod
