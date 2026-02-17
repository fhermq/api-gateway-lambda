/**
 * Migration: 001_create_items_table
 * Description: Creates the items DynamoDB table with schema, GSI, and configuration
 * 
 * This migration script creates the DynamoDB table for storing items.
 * It should be run once per environment (dev, staging, prod).
 * 
 * Usage:
 *   node 001_create_items_table.js --environment dev
 *   node 001_create_items_table.js --environment staging
 *   node 001_create_items_table.js --environment prod
 */

const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const environmentArg = args.find(arg => arg.startsWith('--environment'));
const environment = environmentArg ? environmentArg.split('=')[1] : process.env.ENVIRONMENT || 'dev';

if (!['dev', 'staging', 'prod'].includes(environment)) {
  console.error(`Invalid environment: ${environment}. Must be one of: dev, staging, prod`);
  process.exit(1);
}

// Initialize DynamoDB client
const dynamodb = new AWS.DynamoDB({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Load schema
const schemaPath = path.join(__dirname, '../schemas/items.json');
const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));

// Table name with environment suffix
const tableName = `${schema.tableName}-${environment}`;

/**
 * Create the items table
 */
async function createTable() {
  const params = {
    TableName: tableName,
    KeySchema: [
      {
        AttributeName: schema.primaryKey.partitionKey.name,
        KeyType: 'HASH' // Partition key
      }
    ],
    AttributeDefinitions: [
      {
        AttributeName: schema.primaryKey.partitionKey.name,
        AttributeType: schema.primaryKey.partitionKey.type
      },
      // Add GSI attributes
      {
        AttributeName: 'status',
        AttributeType: 'S'
      },
      {
        AttributeName: 'createdAt',
        AttributeType: 'N'
      }
    ],
    BillingMode: 'PAY_PER_REQUEST', // On-demand billing
    GlobalSecondaryIndexes: [
      {
        IndexName: 'status-index',
        KeySchema: [
          {
            AttributeName: 'status',
            KeyType: 'HASH'
          },
          {
            AttributeName: 'createdAt',
            KeyType: 'RANGE'
          }
        ],
        Projection: {
          ProjectionType: 'ALL'
        }
      }
    ],
    SSESpecification: {
      Enabled: true,
      SSEType: 'AES256' // AWS managed encryption
    },
    PointInTimeRecoverySpecification: {
      PointInTimeRecoveryEnabled: true
    },
    Tags: [
      {
        Key: 'Environment',
        Value: environment
      },
      {
        Key: 'Application',
        Value: 'api-gateway-lambda'
      },
      {
        Key: 'ManagedBy',
        Value: 'Terraform'
      }
    ]
  };

  try {
    console.log(`Creating table: ${tableName}...`);
    const result = await dynamodb.createTable(params).promise();
    console.log(`✓ Table created successfully`);
    console.log(`  Table ARN: ${result.TableDescription.TableArn}`);
    console.log(`  Table Status: ${result.TableDescription.TableStatus}`);
    
    // Wait for table to be active
    console.log(`Waiting for table to become active...`);
    await dynamodb.waitFor('tableExists', { TableName: tableName }).promise();
    console.log(`✓ Table is now active`);
    
    return result;
  } catch (error) {
    if (error.code === 'ResourceInUseException') {
      console.log(`✓ Table already exists: ${tableName}`);
      return null;
    }
    console.error(`✗ Error creating table: ${error.message}`);
    throw error;
  }
}

/**
 * Enable TTL on the table
 */
async function enableTTL() {
  const params = {
    TableName: tableName,
    TimeToLiveSpecification: {
      AttributeName: 'ttl',
      Enabled: true
    }
  };

  try {
    console.log(`Enabling TTL on table...`);
    await dynamodb.updateTimeToLive(params).promise();
    console.log(`✓ TTL enabled successfully`);
  } catch (error) {
    if (error.code === 'ValidationException' && error.message.includes('TimeToLive')) {
      console.log(`✓ TTL already enabled or not available`);
      return;
    }
    console.error(`✗ Error enabling TTL: ${error.message}`);
    throw error;
  }
}

/**
 * Verify table schema
 */
async function verifyTable() {
  try {
    console.log(`Verifying table schema...`);
    const result = await dynamodb.describeTable({ TableName: tableName }).promise();
    const table = result.Table;
    
    console.log(`✓ Table verification passed`);
    console.log(`  Table Name: ${table.TableName}`);
    console.log(`  Table Status: ${table.TableStatus}`);
    console.log(`  Item Count: ${table.ItemCount}`);
    console.log(`  Table Size: ${table.TableSizeBytes} bytes`);
    console.log(`  Billing Mode: ${table.BillingModeSummary?.BillingMode || 'PROVISIONED'}`);
    console.log(`  Encryption: ${table.SSEDescription?.Status || 'Not enabled'}`);
    console.log(`  PITR: ${table.PointInTimeRecoveryDescription?.PointInTimeRecoveryStatus || 'Not enabled'}`);
    console.log(`  GSI Count: ${table.GlobalSecondaryIndexes?.length || 0}`);
    
    if (table.GlobalSecondaryIndexes) {
      table.GlobalSecondaryIndexes.forEach(gsi => {
        console.log(`    - ${gsi.IndexName}: ${gsi.IndexStatus}`);
      });
    }
    
    return table;
  } catch (error) {
    console.error(`✗ Error verifying table: ${error.message}`);
    throw error;
  }
}

/**
 * Main migration function
 */
async function migrate() {
  try {
    console.log(`\n=== DynamoDB Migration: Create Items Table ===`);
    console.log(`Environment: ${environment}`);
    console.log(`Table Name: ${tableName}`);
    console.log(`Region: ${process.env.AWS_REGION || 'us-east-1'}\n`);
    
    // Create table
    await createTable();
    
    // Enable TTL
    await enableTTL();
    
    // Verify table
    await verifyTable();
    
    console.log(`\n✓ Migration completed successfully\n`);
    process.exit(0);
  } catch (error) {
    console.error(`\n✗ Migration failed: ${error.message}\n`);
    process.exit(1);
  }
}

// Run migration
migrate();
