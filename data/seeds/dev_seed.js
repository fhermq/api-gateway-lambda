/**
 * Seed Data: dev_seed
 * Description: Populates the items table with sample data for development environment
 * 
 * This seed script creates sample items in the DynamoDB table for testing and development.
 * It should only be run in the dev environment.
 * 
 * Usage:
 *   node dev_seed.js
 *   node dev_seed.js --clear (clears existing data first)
 */

const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Parse command line arguments
const args = process.argv.slice(2);
const shouldClear = args.includes('--clear');

// Initialize DynamoDB client
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

const tableName = process.env.DYNAMODB_TABLE || 'items-dev';

/**
 * Sample items for seeding
 */
const sampleItems = [
  {
    id: uuidv4(),
    name: 'Laptop',
    description: 'High-performance laptop for development',
    status: 'active',
    createdAt: Math.floor(Date.now() / 1000) - 86400 * 7, // 7 days ago
    updatedAt: Math.floor(Date.now() / 1000) - 86400 * 2, // 2 days ago
    createdBy: 'admin@example.com',
    version: 2
  },
  {
    id: uuidv4(),
    name: 'Monitor',
    description: '4K Ultra HD monitor',
    status: 'active',
    createdAt: Math.floor(Date.now() / 1000) - 86400 * 5, // 5 days ago
    updatedAt: Math.floor(Date.now() / 1000) - 86400 * 1, // 1 day ago
    createdBy: 'admin@example.com',
    version: 1
  },
  {
    id: uuidv4(),
    name: 'Keyboard',
    description: 'Mechanical keyboard with RGB lighting',
    status: 'active',
    createdAt: Math.floor(Date.now() / 1000) - 86400 * 3, // 3 days ago
    updatedAt: Math.floor(Date.now() / 1000),
    createdBy: 'user@example.com',
    version: 1
  },
  {
    id: uuidv4(),
    name: 'Mouse',
    description: 'Wireless mouse',
    status: 'inactive',
    createdAt: Math.floor(Date.now() / 1000) - 86400 * 10, // 10 days ago
    updatedAt: Math.floor(Date.now() / 1000) - 86400 * 5, // 5 days ago
    createdBy: 'admin@example.com',
    version: 1
  },
  {
    id: uuidv4(),
    name: 'USB Hub',
    description: 'Multi-port USB 3.0 hub',
    status: 'archived',
    createdAt: Math.floor(Date.now() / 1000) - 86400 * 30, // 30 days ago
    updatedAt: Math.floor(Date.now() / 1000) - 86400 * 15, // 15 days ago
    createdBy: 'admin@example.com',
    version: 1
  }
];

/**
 * Clear existing data from table
 */
async function clearTable() {
  try {
    console.log(`Clearing existing data from ${tableName}...`);
    
    // Scan all items
    const scanParams = {
      TableName: tableName,
      ProjectionExpression: 'id'
    };
    
    let items = [];
    let lastEvaluatedKey;
    
    do {
      const result = await dynamodb.scan({
        ...scanParams,
        ExclusiveStartKey: lastEvaluatedKey
      }).promise();
      
      items = items.concat(result.Items);
      lastEvaluatedKey = result.LastEvaluatedKey;
    } while (lastEvaluatedKey);
    
    // Delete all items
    if (items.length > 0) {
      console.log(`Found ${items.length} items to delete...`);
      
      for (const item of items) {
        await dynamodb.delete({
          TableName: tableName,
          Key: { id: item.id }
        }).promise();
      }
      
      console.log(`✓ Cleared ${items.length} items`);
    } else {
      console.log(`✓ Table is already empty`);
    }
  } catch (error) {
    console.error(`✗ Error clearing table: ${error.message}`);
    throw error;
  }
}

/**
 * Insert sample items
 */
async function seedItems() {
  try {
    console.log(`Seeding ${sampleItems.length} items into ${tableName}...`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const item of sampleItems) {
      try {
        await dynamodb.put({
          TableName: tableName,
          Item: item
        }).promise();
        
        successCount++;
        console.log(`  ✓ Created: ${item.name} (${item.id})`);
      } catch (error) {
        errorCount++;
        console.error(`  ✗ Failed to create ${item.name}: ${error.message}`);
      }
    }
    
    console.log(`\n✓ Seeding completed: ${successCount} items created, ${errorCount} errors`);
    return { successCount, errorCount };
  } catch (error) {
    console.error(`✗ Error seeding items: ${error.message}`);
    throw error;
  }
}

/**
 * Verify seeded data
 */
async function verifyData() {
  try {
    console.log(`\nVerifying seeded data...`);
    
    const result = await dynamodb.scan({
      TableName: tableName
    }).promise();
    
    console.log(`✓ Table contains ${result.Items.length} items`);
    
    // Show summary by status
    const byStatus = {};
    result.Items.forEach(item => {
      byStatus[item.status] = (byStatus[item.status] || 0) + 1;
    });
    
    console.log(`\nItems by status:`);
    Object.entries(byStatus).forEach(([status, count]) => {
      console.log(`  - ${status}: ${count}`);
    });
    
    return result.Items;
  } catch (error) {
    console.error(`✗ Error verifying data: ${error.message}`);
    throw error;
  }
}

/**
 * Main seed function
 */
async function seed() {
  try {
    console.log(`\n=== DynamoDB Seed: Development Data ===`);
    console.log(`Table: ${tableName}`);
    console.log(`Region: ${process.env.AWS_REGION || 'us-east-1'}\n`);
    
    // Clear existing data if requested
    if (shouldClear) {
      await clearTable();
    }
    
    // Seed items
    await seedItems();
    
    // Verify data
    await verifyData();
    
    console.log(`\n✓ Seed completed successfully\n`);
    process.exit(0);
  } catch (error) {
    console.error(`\n✗ Seed failed: ${error.message}\n`);
    process.exit(1);
  }
}

// Run seed
seed();
