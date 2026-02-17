// Unit tests for list handler
// Property 3: Input Validation Prevents Invalid Operations
// Validates: Requirements 3.3

import { listItems } from '../../handlers/list';
import * as dynamodb from '../../utils/dynamodb';

jest.mock('../../utils/dynamodb');

describe('List Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Property 3: Input Validation Prevents Invalid Operations', () => {
    it('should return 200 with items for valid query', async () => {
      const mockItems = [
        {
          id: 'item-1',
          name: 'Item 1',
          status: 'active' as const,
          createdAt: 1000,
          updatedAt: 1000,
          createdBy: 'system',
          version: 1,
        },
      ];

      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: mockItems,
        count: 1,
      });

      const result = await listItems({ limit: 10 }, 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body.items).toEqual(mockItems);
      expect(result.body.count).toBe(1);
    });

    it('should return 400 for invalid limit (negative)', async () => {
      const result = await listItems({ limit: -1 }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for invalid limit (exceeds max)', async () => {
      const result = await listItems({ limit: 101 }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for invalid offset (negative)', async () => {
      const result = await listItems({ offset: -1 }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });
  });

  describe('Pagination', () => {
    it('should handle limit parameter', async () => {
      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: [],
        count: 0,
      });

      await listItems({ limit: 50 }, 'req-123');

      expect(dynamodb.dbClient.scan).toHaveBeenCalledWith(50, undefined);
    });

    it('should handle offset parameter', async () => {
      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: [],
        count: 0,
      });

      await listItems({ offset: 10 }, 'req-123');

      expect(dynamodb.dbClient.scan).toHaveBeenCalledWith(undefined, 10);
    });

    it('should use default limit when not provided', async () => {
      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: [],
        count: 0,
      });

      await listItems({}, 'req-123');

      expect(dynamodb.dbClient.scan).toHaveBeenCalledWith(undefined, undefined);
    });
  });

  describe('Empty list handling', () => {
    it('should return empty items array', async () => {
      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: [],
        count: 0,
      });

      const result = await listItems({}, 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body.items).toEqual([]);
      expect(result.body.count).toBe(0);
    });

    it('should handle multiple items', async () => {
      const mockItems = [
        {
          id: 'item-1',
          name: 'Item 1',
          status: 'active' as const,
          createdAt: 1000,
          updatedAt: 1000,
          createdBy: 'system',
          version: 1,
        },
        {
          id: 'item-2',
          name: 'Item 2',
          status: 'inactive' as const,
          createdAt: 2000,
          updatedAt: 2000,
          createdBy: 'system',
          version: 1,
        },
      ];

      (dynamodb.dbClient.scan as jest.Mock).mockResolvedValue({
        items: mockItems,
        count: 2,
      });

      const result = await listItems({}, 'req-123');

      expect(result.statusCode).toBe(200);
      expect(result.body.items.length).toBe(2);
      expect(result.body.count).toBe(2);
    });
  });

  describe('Error handling', () => {
    it('should return 500 on DynamoDB error', async () => {
      (dynamodb.dbClient.scan as jest.Mock).mockRejectedValue(
        new Error('DynamoDB error'),
      );

      const result = await listItems({}, 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });
  });
});
