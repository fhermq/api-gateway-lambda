# API Handler Lambda Function

TypeScript-based Lambda function for CRUD operations on items.

## Project Structure

```
src/
├── handlers/          # HTTP request handlers
│   ├── create.ts     # POST /items
│   ├── read.ts       # GET /items/{id}
│   ├── list.ts       # GET /items
│   ├── update.ts     # PUT /items/{id}
│   └── delete.ts     # DELETE /items/{id}
├── utils/            # Utility functions
│   ├── logger.ts     # Structured logging
│   ├── dynamodb.ts   # DynamoDB client
│   └── validators.ts # Input validation
├── types/            # TypeScript type definitions
│   └── index.ts      # Shared types
└── index.ts          # Lambda handler entry point
```

## Setup

Install dependencies:
```bash
npm install
```

## Development

Build TypeScript:
```bash
npm run build
```

Watch mode:
```bash
npm run dev
```

Lint code:
```bash
npm run lint
npm run lint:fix
```

## Testing

Run all tests:
```bash
npm test
```

Run specific test suites:
```bash
npm run test:unit
npm run test:integration
npm run test:smoke
```

Generate coverage report:
```bash
npm run test:coverage
```

## Building for Lambda

Build and package:
```bash
npm run build
npm run package
```

This creates `lambda-function.zip` ready for deployment.

## Environment Variables

- `DYNAMODB_TABLE_NAME` - DynamoDB table name (default: items)
- `AWS_REGION` - AWS region (default: us-east-1)

## API Endpoints

### Create Item
```
POST /items
Content-Type: application/json

{
  "name": "Item name",
  "description": "Optional description",
  "status": "active"
}
```

### List Items
```
GET /items?limit=10&offset=0
```

### Get Item
```
GET /items/{id}
```

### Update Item
```
PUT /items/{id}
Content-Type: application/json

{
  "name": "Updated name",
  "status": "inactive"
}
```

### Delete Item
```
DELETE /items/{id}
```

## Error Handling

All errors return JSON responses with:
- `error` - Error type
- `message` - Human-readable message
- `requestId` - Request ID for tracking
- `timestamp` - Error timestamp
