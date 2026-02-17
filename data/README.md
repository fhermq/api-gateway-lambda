# Data Layer

This directory contains DynamoDB schema definitions, migration scripts, and seed data for the serverless monorepo application.

## Directory Structure

```
data/
├── schemas/
│   └── items.json              # DynamoDB table schema definition
├── migrations/
│   └── 001_create_items_table.js  # Migration script to create items table
├── seeds/
│   └── dev_seed.js             # Seed data for development environment
└── README.md                   # This file
```

## Schema Definition

### items.json

The `items.json` file defines the DynamoDB table schema for storing items. It includes:

- **Table Name**: `items` (environment-specific: `items-dev`, `items-staging`, `items-prod`)
- **Primary Key**: `id` (String, partition key)
- **Attributes**:
  - `id` (String): Unique identifier (UUID)
  - `name` (String): Item name (required, max 255 chars)
  - `description` (String): Item description (optional)
  - `status` (String): Item status - `active`, `inactive`, or `archived` (required)
  - `createdAt` (Number): Unix timestamp when item was created (required)
  - `updatedAt` (Number): Unix timestamp when item was last updated (required)
  - `createdBy` (String): User who created the item (optional)
  - `version` (Number): Item version for optimistic locking (required)
  - `ttl` (Number): Unix timestamp for TTL expiration (optional)

### Global Secondary Indexes

**status-index**:
- Partition Key: `status`
- Sort Key: `createdAt`
- Projection: ALL
- Billing Mode: PAY_PER_REQUEST

This index enables efficient queries for items by status and creation time.

### Table Configuration

- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Encryption**: AWS managed keys (AES256)
- **Point-in-Time Recovery**: Enabled
- **TTL**: Supported via `ttl` attribute

## Migrations

### 001_create_items_table.js

This migration script creates the DynamoDB table with the schema defined in `items.json`.

#### Prerequisites

- AWS credentials configured (via IAM role, environment variables, or AWS CLI)
- Node.js 14+ installed
- AWS SDK for JavaScript installed (`npm install aws-sdk`)

#### Usage

```bash
# Create table in dev environment
node data/migrations/001_create_items_table.js --environment dev

# Create table in staging environment
node data/migrations/001_create_items_table.js --environment staging

# Create table in production environment
node data/migrations/001_create_items_table.js --environment prod

# Using environment variable
ENVIRONMENT=dev node data/migrations/001_create_items_table.js
```

#### What It Does

1. Loads the schema from `schemas/items.json`
2. Creates the DynamoDB table with environment-specific naming
3. Configures the Global Secondary Index (status-index)
4. Enables encryption (AWS managed)
5. Enables Point-in-Time Recovery
6. Enables TTL support
7. Waits for the table to become active
8. Verifies the table configuration

#### Output

```
=== DynamoDB Migration: Create Items Table ===
Environment: dev
Table Name: items-dev
Region: us-east-1

Creating table: items-dev...
✓ Table created successfully
  Table ARN: arn:aws:dynamodb:us-east-1:123456789012:table/items-dev
  Table Status: CREATING
Waiting for table to become active...
✓ Table is now active
Enabling TTL on table...
✓ TTL enabled successfully
Verifying table schema...
✓ Table verification passed
  Table Name: items-dev
  Table Status: ACTIVE
  Item Count: 0
  Table Size: 0 bytes
  Billing Mode: PAY_PER_REQUEST
  Encryption: ENABLED
  PITR: ENABLED
  GSI Count: 1
    - status-index: ACTIVE

✓ Migration completed successfully
```

## Seed Data

### dev_seed.js

This script populates the DynamoDB table with sample data for development and testing.

#### Prerequisites

- DynamoDB table must exist (run migration first)
- AWS credentials configured
- Node.js 14+ installed
- AWS SDK for JavaScript installed (`npm install aws-sdk`)
- UUID package installed (`npm install uuid`)

#### Usage

```bash
# Seed development table with sample data
DYNAMODB_TABLE=items-dev node data/seeds/dev_seed.js

# Clear existing data and reseed
DYNAMODB_TABLE=items-dev node data/seeds/dev_seed.js --clear

# Using environment variable for table name
export DYNAMODB_TABLE=items-dev
node data/seeds/dev_seed.js
```

#### Sample Data

The seed script creates 5 sample items:

1. **Laptop** - Active item created 7 days ago, updated 2 days ago
2. **Monitor** - Active item created 5 days ago, updated 1 day ago
3. **Keyboard** - Active item created 3 days ago, updated today
4. **Mouse** - Inactive item created 10 days ago, updated 5 days ago
5. **USB Hub** - Archived item created 30 days ago, updated 15 days ago

#### Output

```
=== DynamoDB Seed: Development Data ===
Table: items-dev
Region: us-east-1

Seeding 5 items into items-dev...
  ✓ Created: Laptop (550e8400-e29b-41d4-a716-446655440000)
  ✓ Created: Monitor (550e8400-e29b-41d4-a716-446655440001)
  ✓ Created: Keyboard (550e8400-e29b-41d4-a716-446655440002)
  ✓ Created: Mouse (550e8400-e29b-41d4-a716-446655440003)
  ✓ Created: USB Hub (550e8400-e29b-41d4-a716-446655440004)

✓ Seeding completed: 5 items created, 0 errors

Verifying seeded data...
✓ Table contains 5 items

Items by status:
  - active: 3
  - inactive: 1
  - archived: 1

✓ Seed completed successfully
```

## Access Patterns

The DynamoDB table supports the following access patterns:

### 1. Get Item by ID

```javascript
const params = {
  TableName: 'items-dev',
  Key: { id: 'item-uuid' }
};
const result = await dynamodb.get(params).promise();
```

### 2. List All Items (with pagination)

```javascript
const params = {
  TableName: 'items-dev',
  Limit: 10
};
const result = await dynamodb.scan(params).promise();
```

### 3. Query Items by Status

```javascript
const params = {
  TableName: 'items-dev',
  IndexName: 'status-index',
  KeyConditionExpression: 'status = :status',
  ExpressionAttributeValues: {
    ':status': 'active'
  }
};
const result = await dynamodb.query(params).promise();
```

### 4. Query Items by Status and Creation Date

```javascript
const params = {
  TableName: 'items-dev',
  IndexName: 'status-index',
  KeyConditionExpression: 'status = :status AND createdAt > :date',
  ExpressionAttributeValues: {
    ':status': 'active',
    ':date': Math.floor(Date.now() / 1000) - 86400 * 7 // Last 7 days
  }
};
const result = await dynamodb.query(params).promise();
```

### 5. Create Item

```javascript
const params = {
  TableName: 'items-dev',
  Item: {
    id: uuidv4(),
    name: 'New Item',
    description: 'Item description',
    status: 'active',
    createdAt: Math.floor(Date.now() / 1000),
    updatedAt: Math.floor(Date.now() / 1000),
    createdBy: 'user@example.com',
    version: 1
  }
};
const result = await dynamodb.put(params).promise();
```

### 6. Update Item

```javascript
const params = {
  TableName: 'items-dev',
  Key: { id: 'item-uuid' },
  UpdateExpression: 'SET #name = :name, updatedAt = :updatedAt, #version = :version',
  ExpressionAttributeNames: {
    '#name': 'name',
    '#version': 'version'
  },
  ExpressionAttributeValues: {
    ':name': 'Updated Name',
    ':updatedAt': Math.floor(Date.now() / 1000),
    ':version': 2
  }
};
const result = await dynamodb.update(params).promise();
```

### 7. Delete Item

```javascript
const params = {
  TableName: 'items-dev',
  Key: { id: 'item-uuid' }
};
const result = await dynamodb.delete(params).promise();
```

## Environment-Specific Tables

The application uses environment-specific table names:

- **Development**: `items-dev`
- **Staging**: `items-staging`
- **Production**: `items-prod`

Each environment has its own isolated table with the same schema. This ensures:

- Data isolation between environments
- Independent scaling and billing
- Safe testing without affecting production data
- Easy cleanup of development/staging data

## Best Practices

### 1. Versioning

Use the `version` attribute for optimistic locking to prevent concurrent update conflicts:

```javascript
// Update only if version matches
const params = {
  TableName: 'items-dev',
  Key: { id: 'item-uuid' },
  UpdateExpression: 'SET #name = :name, #version = :version, updatedAt = :updatedAt',
  ConditionExpression: '#version = :expectedVersion',
  ExpressionAttributeNames: {
    '#name': 'name',
    '#version': 'version'
  },
  ExpressionAttributeValues: {
    ':name': 'Updated Name',
    ':version': 2,
    ':expectedVersion': 1,
    ':updatedAt': Math.floor(Date.now() / 1000)
  }
};
```

### 2. TTL for Automatic Cleanup

Use the `ttl` attribute to automatically delete expired items:

```javascript
// Item expires in 30 days
const expirationTime = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60);
const params = {
  TableName: 'items-dev',
  Item: {
    id: uuidv4(),
    name: 'Temporary Item',
    status: 'active',
    createdAt: Math.floor(Date.now() / 1000),
    updatedAt: Math.floor(Date.now() / 1000),
    version: 1,
    ttl: expirationTime
  }
};
```

### 3. Batch Operations

Use batch operations for better performance when working with multiple items:

```javascript
const params = {
  RequestItems: {
    'items-dev': [
      {
        PutRequest: {
          Item: { id: uuidv4(), name: 'Item 1', ... }
        }
      },
      {
        PutRequest: {
          Item: { id: uuidv4(), name: 'Item 2', ... }
        }
      }
    ]
  }
};
const result = await dynamodb.batchWriteItem(params).promise();
```

### 4. Pagination

Always implement pagination for scan and query operations:

```javascript
let items = [];
let lastEvaluatedKey;

do {
  const result = await dynamodb.scan({
    TableName: 'items-dev',
    Limit: 10,
    ExclusiveStartKey: lastEvaluatedKey
  }).promise();
  
  items = items.concat(result.Items);
  lastEvaluatedKey = result.LastEvaluatedKey;
} while (lastEvaluatedKey);
```

## Troubleshooting

### Table Not Found

**Error**: `ResourceNotFoundException: Requested resource not found`

**Solution**: Run the migration script to create the table:
```bash
node data/migrations/001_create_items_table.js --environment dev
```

### Insufficient Permissions

**Error**: `AccessDeniedException: User is not authorized to perform: dynamodb:PutItem`

**Solution**: Ensure your AWS credentials have DynamoDB permissions. Check IAM role policies.

### Provisioned Throughput Exceeded

**Error**: `ProvisionedThroughputExceededException`

**Solution**: The table is using on-demand billing, so this shouldn't occur. If it does, check for hot partitions or consider increasing capacity.

### TTL Not Working

**Issue**: Items with expired TTL are not being deleted

**Solution**: TTL deletion can take up to 48 hours. This is normal DynamoDB behavior.

## Related Documentation

- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [DynamoDB Query and Scan Operations](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html)
- [DynamoDB Global Secondary Indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
