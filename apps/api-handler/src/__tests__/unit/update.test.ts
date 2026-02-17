// Unit tests for update handler
// Property 4: Database Error Handling and Logging
// Validates: Requirements 3.4, 3.8

import { updateItem } from '../../handlers/update';
import * as dynamodb from '../../utils/dynamodb';

jest.mock('../../utils/dynamodb');

describe('Update Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Property 4: Database Error Handling and Logging', () => {
    it('should update item and return 200', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Old Name',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      const updatedItem = {
        id: 'item-1',
        name: 'New Name',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 2,
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.update as jest.Mock).mockResolvedValue(updatedItem);

      const result = await updateItem('item-1', { name: 'New Name' }, 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body.name).toBe('New Name');
      expect(result.body.version).toBe(2);
    });

    it('should increment version on update', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Item',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 5,
      };

      const updatedItem = {
        ...existingItem,
        version: 6,
        updatedAt: expect.any(Number),
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.update as jest.Mock).mockResolvedValue(updatedItem);

      const result = await updateItem('item-1', { status: 'inactive' }, 'req-123');

      expect(result.body.version).toBe(6);
    });

    it('should return 404 for non-existent item', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await updateItem('non-existent', { name: 'New' }, 'req-123');

      expect(result.statusCode).toBe(404);
      expect(result.body.error).toBe('NotFound');
    });

    it('should return 500 on DynamoDB error', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Item',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.update as jest.Mock).mockRejectedValue(
        new Error('DynamoDB error'),
      );

      const result = await updateItem('item-1', { name: 'New' }, 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });
  });

  describe('Validation errors', () => {
    it('should return 400 for invalid name (empty)', async () => {
      const result = await updateItem('item-1', { name: '' }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for invalid status', async () => {
      const result = await updateItem('item-1', { status: 'invalid' }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });
  });

  describe('Partial updates', () => {
    it('should update only provided fields', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Original',
        description: 'Original desc',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      const updatedItem = {
        ...existingItem,
        name: 'Updated',
        version: 2,
        updatedAt: expect.any(Number),
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.update as jest.Mock).mockResolvedValue(updatedItem);

      const result = await updateItem('item-1', { name: 'Updated' }, 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body.name).toBe('Updated');
    });
  });

  describe('Edge cases', () => {
    it('should handle updating to same values', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Item',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      const updatedItem = {
        ...existingItem,
        version: 2,
        updatedAt: expect.any(Number),
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.update as jest.Mock).mockResolvedValue(updatedItem);

      const result = await updateItem('item-1', { name: 'Item' }, 'req-123');

      expect(result.statusCode).toBe(200);
    });
  });
});
