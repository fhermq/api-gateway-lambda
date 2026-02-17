# Design Document: JWT Lambda Authorizer

## Overview

The JWT Lambda Authorizer system provides enterprise-grade token-based authentication for serverless APIs on AWS. The architecture consists of three main components:

1. **Token Endpoint** - A Lambda handler that issues JWT tokens to authenticated clients
2. **Lambda Authorizer** - A Lambda function that validates tokens before routing requests to handlers
3. **Client Manager** - A Lambda handler that manages OAuth client registration and credentials

The system uses AWS Secrets Manager for secure secret storage, DynamoDB for client and token metadata, and API Gateway for request routing. All components follow AWS best practices for security, performance, and observability.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         API Client                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  API Gateway    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        │         ┌──────────▼──────────┐         │
        │         │ Lambda Authorizer   │         │
        │         │ (Token Validation)  │         │
        │         └──────────┬──────────┘         │
        │                    │                    │
        │         ┌──────────▼──────────┐         │
        │         │  Secrets Manager    │         │
        │         │  (JWT Secret)       │         │
        │         └─────────────────────┘         │
        │                                         │
   ┌────▼──────┐  ┌──────────────┐  ┌──────────┐ │
   │  Token    │  │   Client     │  │ Handler  │ │
   │ Endpoint  │  │   Manager    │  │ Lambda   │ │
   └────┬──────┘  └──────┬───────┘  └──────────┘ │
        │                │                       │
        └────────┬───────┴───────────────────────┘
                 │
        ┌────────▼────────┐
        │    DynamoDB     │
        │ (Clients, etc)  │
        └─────────────────┘
```

## Components

### 1. Token Endpoint Lambda Handler

**Purpose**: Issues JWT tokens to authenticated clients

**Input**:
```json
{
  "grant_type": "client_credentials",
  "client_id": "string",
  "client_secret": "string"
}
```

**Output**:
```json
{
  "access_token": "string",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**Key Functions**:
- Validate client credentials against DynamoDB
- Retrieve JWT secret from Secrets Manager
- Generate JWT token with standard claims
- Return token in OAuth 2.0 format

### 2. Lambda Authorizer

**Purpose**: Validates JWT tokens and returns IAM policy

**Input**:
```json
{
  "type": "TOKEN",
  "authorizationToken": "Bearer eyJhbGc...",
  "methodArn": "arn:aws:execute-api:..."
}
```

**Output**:
```json
{
  "principalId": "client_id",
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "execute-api:Invoke",
      "Effect": "Allow",
      "Resource": "arn:aws:execute-api:..."
    }]
  },
  "context": {
    "sub": "client_id",
    "iss": "issuer",
    "aud": "audience"
  }
}
```

**Key Functions**:
- Extract Bearer token from Authorization header
- Validate token signature using JWT secret
- Validate token claims (exp, iss, aud)
- Cache authorization decisions
- Return Allow or Deny policy

### 3. Client Manager Lambda Handler

**Purpose**: Manages OAuth client registration and credentials

**Input** (Create):
```json
{
  "action": "create",
  "name": "My App",
  "description": "My application"
}
```

**Output**:
```json
{
  "client_id": "unique_id",
  "client_secret": "secret_value",
  "name": "My App",
  "created_at": "2024-01-01T00:00:00Z"
}
```

## Data Models

### JWT Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "client_id",
    "iss": "https://api.example.com",
    "aud": "api.example.com",
    "exp": 1234567890,
    "iat": 1234567800
  }
}
```

### DynamoDB Client Table

**Table Name**: `{environment}-jwt-clients`

**Attributes**:
- `client_id` (String, Partition Key)
- `client_secret_hash` (String)
- `name` (String)
- `description` (String)
- `created_at` (String)
- `updated_at` (String)
- `is_active` (Boolean)

## Configuration

### Environment Variables

```
JWT_SECRET_NAME=jwt-secret-{environment}
JWT_ISSUER=https://api.example.com
JWT_AUDIENCE=api.example.com
JWT_EXPIRATION_SECONDS=3600
AUTHORIZER_CACHE_TTL_SECONDS=300
CLIENTS_TABLE_NAME={environment}-jwt-clients
AWS_REGION=us-east-1
LOG_LEVEL=INFO
```

## Security Considerations

1. **Secret Storage**: JWT secrets stored in Secrets Manager, never in code
2. **Client Secret Hashing**: Client secrets hashed with bcrypt before storage
3. **Token Signature**: HMAC-SHA256 for token signing
4. **HTTPS Only**: All endpoints require HTTPS
5. **Token Expiration**: Short-lived access tokens (1 hour default)
6. **Logging**: Sensitive data never logged; only token metadata logged
7. **Rate Limiting**: API Gateway rate limiting on Token Endpoint

## Error Handling

### Token Endpoint Errors

| Error | Status | Response |
|-------|--------|----------|
| Invalid credentials | 401 | `{"error": "invalid_client"}` |
| Missing parameters | 400 | `{"error": "invalid_request"}` |
| Invalid grant type | 400 | `{"error": "unsupported_grant_type"}` |
| Server error | 500 | `{"error": "server_error"}` |

### Lambda Authorizer Errors

| Error | Action |
|-------|--------|
| Missing Authorization header | Deny request |
| Invalid Bearer format | Deny request |
| Malformed token | Deny request |
| Invalid signature | Deny request |
| Expired token | Deny request |
| Invalid issuer | Deny request |
| Invalid audience | Deny request |

## Correctness Properties

### Property 1: Token Generation Includes Required Claims

*For any* valid client credentials, when a token is generated, the resulting JWT SHALL contain all required claims: `sub`, `iss`, `aud`, `exp`, and `iat`.

**Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**

### Property 2: Token Expiration Matches Configuration

*For any* token generation with a configured expiration duration, the `exp` claim in the token SHALL be set to approximately the current time plus the configured duration (within 1 second tolerance).

**Validates: Requirements 1.2**

### Property 3: Invalid Credentials Return 401

*For any* invalid client credentials sent to the Token_Endpoint, the response SHALL be 401 Unauthorized.

**Validates: Requirements 1.6, 6.3, 6.4**

### Property 4: Valid Token Produces Allow Policy

*For any* valid JWT token with correct signature and non-expired claims, the Lambda_Authorizer SHALL return an IAM policy with Effect "Allow".

**Validates: Requirements 2.2, 4.1, 4.2, 4.3, 4.4**

### Property 5: Invalid Token Produces Deny Policy

*For any* invalid JWT token (invalid signature, expired, or invalid claims), the Lambda_Authorizer SHALL return an IAM policy with Effect "Deny".

**Validates: Requirements 2.3, 2.6, 2.7, 4.5**

### Property 6: Malformed Authorization Header Denied

*For any* Authorization header that is not in the format "Bearer {token}", the Lambda_Authorizer SHALL deny the request.

**Validates: Requirements 2.5, 9.3**

### Property 7: Authorization Decision Caching

*For any* token that has been successfully validated, when the same token is presented again within the cache TTL, the Lambda_Authorizer SHALL return the cached decision without re-validating.

**Validates: Requirements 5.1, 5.2**

### Property 8: Cache Expiration Triggers Re-validation

*For any* token that has been cached, when the cache TTL expires and the token is presented again, the Lambda_Authorizer SHALL re-validate the token signature.

**Validates: Requirements 5.3**

### Property 9: Subject Claim Extraction

*For any* valid token, the Lambda_Authorizer SHALL extract the `sub` (subject) claim and include it in the authorization context passed to the handler Lambda.

**Validates: Requirements 4.6, 10.4**

### Property 10: Client Creation Generates Unique Credentials

*For any* two client creation requests, the system SHALL generate unique `client_id` and `client_secret` values for each client.

**Validates: Requirements 11.1**

### Property 11: Created Clients Are Retrievable

*For any* client that has been created, the system SHALL be able to retrieve the client details from DynamoDB using the `client_id`.

**Validates: Requirements 11.2, 11.4**

### Property 12: Valid Client Credentials Produce Token

*For any* token request with valid `client_id` and `client_secret`, the Token_Endpoint SHALL issue an access token with the `client_id` as the `sub` claim.

**Validates: Requirements 12.3**
