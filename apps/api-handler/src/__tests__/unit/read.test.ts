// Unit tests for read handler
// Property 2: Lambda Handler Status Codes
// Validates: Requirements 3.2

import { readItem } from '../../handlers/read';
import * as dynamodb from '../../utils/dynamodb';

jest.mock('../../utils/dynamodb');

describe('Read Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Property 2: Lambda Handler Status Codes', () => {
    it('should return 200 for existing item', async () => {
      const mockItem = {
        id: 'item-1',
        name: 'Test Item',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(mockItem);

      const result = await readItem('item-1', 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body).toEqual(mockItem);
    });

    it('should return 404 for non-existent item', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await readItem('non-existent', 'req-123');

      expect(result.statusCode).toBe(404);
      expect(result.body.error).toBe('NotFound');
    });

    it('should return 500 on DynamoDB error', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockRejectedValue(
        new Error('DynamoDB error'),
      );

      const result = await readItem('item-1', 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });
  });

  describe('Successful retrieval', () => {
    it('should retrieve item with all attributes', async () => {
      const mockItem = {
        id: 'item-1',
        name: 'Complete Item',
        description: 'Full description',
        status: 'active' as const,
        createdAt: 1000,
        updatedAt: 2000,
        createdBy: 'user-123',
        version: 5,
      };

      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(mockItem);

      const result = await readItem('item-1', 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body).toEqual(mockItem);
      expect(result.body.version).toBe(5);
    });
  });

  describe('Not found scenarios', () => {
    it('should handle undefined response as not found', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(undefined);

      const result = await readItem('item-1', 'req-123');

      expect(result.statusCode).toBe(404);
    });

    it('should include item ID in error message', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await readItem('missing-item', 'req-123');

      expect(result.body.message).toContain('missing-item');
    });
  });

  describe('Error handling', () => {
    it('should handle network errors', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockRejectedValue(
        new Error('Network timeout'),
      );

      const result = await readItem('item-1', 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });

    it('should include request ID in error response', async () => {
      (dynamodb.dbClient.get as jest.Mock).mockResolvedValue(null);

      const result = await readItem('item-1', 'req-456');

      expect(result.body.requestId).toBe('req-456');
    });
  });
});
