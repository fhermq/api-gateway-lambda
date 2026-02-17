// Unit tests for create handler
// Property 1: CRUD Operations Round Trip
// Validates: Requirements 3.1, 3.8

import { createItem } from '../../handlers/create';
import * as dynamodb from '../../utils/dynamodb';

jest.mock('../../utils/dynamodb');
jest.mock('uuid', () => ({
  v4: () => 'test-uuid-1234',
}));

describe('Create Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Property 1: CRUD Operations Round Trip', () => {
    it('should create item with valid input and return 201', async () => {
      const mockItem = {
        id: 'test-uuid-1234',
        name: 'Test Item',
        description: 'Test Description',
        status: 'active' as const,
        createdAt: expect.any(Number),
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.put as jest.Mock).mockResolvedValue(mockItem);

      const result = await createItem(
        { name: 'Test Item', description: 'Test Description' },
        'req-123',
      );

      expect(result.statusCode).toBe(201);
      expect(result.body).toEqual(mockItem);
      expect(dynamodb.dbClient.put).toHaveBeenCalled();
    });

    it('should create item with minimal input (name only)', async () => {
      const mockItem = {
        id: 'test-uuid-1234',
        name: 'Minimal Item',
        status: 'active' as const,
        createdAt: expect.any(Number),
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.put as jest.Mock).mockResolvedValue(mockItem);

      const result = await createItem({ name: 'Minimal Item' }, 'req-123');

      expect(result.statusCode).toBe(201);
      expect(result.body.name).toBe('Minimal Item');
      expect(result.body.status).toBe('active');
    });

    it('should set default status to active', async () => {
      const mockItem = {
        id: 'test-uuid-1234',
        name: 'Test',
        status: 'active' as const,
        createdAt: expect.any(Number),
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.put as jest.Mock).mockResolvedValue(mockItem);

      const result = await createItem({ name: 'Test' }, 'req-123');

      expect(result.body.status).toBe('active');
    });
  });

  describe('Validation errors', () => {
    it('should return 400 for missing name', async () => {
      const result = await createItem({ description: 'No name' }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for empty name', async () => {
      const result = await createItem({ name: '' }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for name exceeding max length', async () => {
      const longName = 'a'.repeat(256);
      const result = await createItem({ name: longName }, 'req-123');

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });

    it('should return 400 for invalid status', async () => {
      const result = await createItem(
        { name: 'Test', status: 'invalid' },
        'req-123',
      );

      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe('ValidationError');
    });
  });

  describe('DynamoDB error handling', () => {
    it('should return 500 on DynamoDB error', async () => {
      (dynamodb.dbClient.put as jest.Mock).mockRejectedValue(
        new Error('DynamoDB error'),
      );

      const result = await createItem({ name: 'Test' }, 'req-123');

      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe('InternalServerError');
    });
  });

  describe('Edge cases', () => {
    it('should handle description with special characters', async () => {
      const mockItem = {
        id: 'test-uuid-1234',
        name: 'Test',
        description: 'Special chars: !@#$%^&*()',
        status: 'active' as const,
        createdAt: expect.any(Number),
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.put as jest.Mock).mockResolvedValue(mockItem);

      const result = await createItem(
        { name: 'Test', description: 'Special chars: !@#$%^&*()' },
        'req-123',
      );

      expect(result.statusCode).toBe(201);
    });

    it('should generate unique IDs for multiple creates', async () => {
      const mockItem1 = {
        id: 'test-uuid-1234',
        name: 'Item 1',
        status: 'active' as const,
        createdAt: expect.any(Number),
        updatedAt: expect.any(Number),
        createdBy: 'system',
        version: 1,
      };

      (dynamodb.dbClient.put as jest.Mock).mockResolvedValue(mockItem1);

      const result1 = await createItem({ name: 'Item 1' }, 'req-123');
      const result2 = await createItem({ name: 'Item 2' }, 'req-124');

      expect(result1.statusCode).toBe(201);
      expect(result2.statusCode).toBe(201);
    });
  });
});
