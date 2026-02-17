// DynamoDB client and helper functions

import * as AWS from 'aws-sdk';
import { Item } from '../types';

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1',
});

const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME || 'items';

export class DynamoDBClient {
  async get(id: string): Promise<Item | null> {
    try {
      const result = await dynamodb.get({
        TableName: TABLE_NAME,
        Key: { id },
      }).promise();

      return result.Item as Item | undefined || null;
    } catch (error) {
      throw new Error(`Failed to get item: ${error}`);
    }
  }

  async put(item: Item): Promise<Item> {
    try {
      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: item,
      }).promise();

      return item;
    } catch (error) {
      throw new Error(`Failed to put item: ${error}`);
    }
  }

  async update(id: string, updates: Partial<Item>): Promise<Item> {
    try {
      const updateExpression: string[] = [];
      const expressionAttributeValues: Record<string, unknown> = {};
      const expressionAttributeNames: Record<string, string> = {};
      let counter = 0;

      for (const [key, value] of Object.entries(updates)) {
        if (key !== 'id') {
          const placeholder = `:val${counter}`;
          const nameAlias = `#${key}`;
          updateExpression.push(`${nameAlias} = ${placeholder}`);
          expressionAttributeValues[placeholder] = value;
          expressionAttributeNames[nameAlias] = key;
          counter++;
        }
      }

      const result = await dynamodb.update({
        TableName: TABLE_NAME,
        Key: { id },
        UpdateExpression: `SET ${updateExpression.join(', ')}`,
        ExpressionAttributeValues: expressionAttributeValues,
        ExpressionAttributeNames: expressionAttributeNames,
        ReturnValues: 'ALL_NEW',
      }).promise();

      return result.Attributes as Item;
    } catch (error) {
      throw new Error(`Failed to update item: ${error}`);
    }
  }

  async delete(id: string): Promise<void> {
    try {
      await dynamodb.delete({
        TableName: TABLE_NAME,
        Key: { id },
      }).promise();
    } catch (error) {
      throw new Error(`Failed to delete item: ${error}`);
    }
  }

  async scan(limit?: number, offset?: number): Promise<{ items: Item[]; count: number }> {
    try {
      const result = await dynamodb.scan({
        TableName: TABLE_NAME,
        Limit: limit || 100,
        ExclusiveStartKey: offset ? { id: `offset-${offset}` } : undefined,
      }).promise();

      return {
        items: (result.Items as Item[]) || [],
        count: result.Count || 0,
      };
    } catch (error) {
      throw new Error(`Failed to scan items: ${error}`);
    }
  }
}

export const dbClient = new DynamoDBClient();
