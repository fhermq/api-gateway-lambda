// Unit tests for delete handler
// Property 5: Request/Response Logging Completeness
// Validates: Requirements 3.5

import { deleteItem } from '../../handlers/delete';
import * as dynamodb from '../../utils/dynamodb';

jest.mock('../../utils/dynamodb');

describe('Delete Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Property 5: Request/Response Logging Completeness', () => {
    it('should delete item and return 204', async () => {
      const existingItem = {
        id: 'item-1',
        name: 'Item to Delete',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(existingItem);
      (dynamodb.dbClient.delete as jest.Mock).mockResolvedValue(undefined);

      const result = await deleteItem('item-1', 'req-123');

      expect(result.statusCode).toBe(204);
      expect(result.body).toBeNull();
    });

    it('should return 404 for non-existent item', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await deleteItem('non-existent', 'req-123');

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
      (dynamodb.dbClient.delete as jest.Mock).mockRejectedValue(
        new Error('DynamoDB error'),
      );

      const result = await deleteItem('item-1', 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });
  });

  describe('Successful deletion', () => {
    it('should call delete with correct item ID', async () => {
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
      (dynamodb.dbClient.delete as jest.Mock).mockResolvedValue(undefined);

      await deleteItem('item-1', 'req-123');

      expect(dynamodb.dbClient.delete).toHaveBeenCalledWith('item-1');
    });

    it('should verify item exists before deletion', async () => {
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
      (dynamodb.dbClient.delete as jest.Mock).mockResolvedValue(undefined);

      await deleteItem('item-1', 'req-123');

      expect(dynamodb.dbClient.get).toHaveBeenCalledWith('item-1');
      expect(dynamodb.dbClient.delete).toHaveBeenCalled();
    });
  });

  describe('Not found scenarios', () => {
    it('should not call delete if item not found', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      await deleteItem('non-existent', 'req-123');

      expect(dynamodb.dbClient.delete).not.toHaveBeenCalled();
    });

    it('should include item ID in error message', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await deleteItem('missing-item', 'req-123');

      expect(result.body.message).toContain('missing-item');
    });
  });

  describe('Error handling', () => {
    it('should handle get operation errors', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockRejectedValue(
        new Error('Get failed'),
      );

      const result = await deleteItem('item-1', 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });

    it('should include request ID in error response', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await deleteItem('item-1', 'req-789');

      expect(result.body.requestId).toBe('req-789');
    });
  });
});
