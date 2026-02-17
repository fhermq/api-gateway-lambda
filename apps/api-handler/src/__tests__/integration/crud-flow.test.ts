import { handler } from '../../index';
import { mockDynamoDBClient } from '../mocks/dynamodb.mock';

/**
 * Integration Tests: CRUD Flow
 * Tests complete CRUD flow: create, read, update, delete
 * Tests API Gateway request/response transformation
 * Tests error propagation through API Gateway
 * 
 * **Property 1: CRUD Operations Round Trip**
 * **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
 */

describe('Integration: CRUD Flow', () => {
  let createdItemId: string;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDynamoDBClient.reset();
  });

  describe('Complete CRUD Round Trip', () => {
    it('should create, read, update, and delete an item successfully', async () => {
      // Step 1: Create item
      const createEvent = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          name: 'Integration Test Item',
          description: 'Test item for CRUD flow',
          status: 'active',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const createResponse = await handler(createEvent as any, {} as any);
      expect(createResponse.statusCode).toBe(201);

      const createdItem = JSON.parse(createResponse.body);
      createdItemId = createdItem.id;
      expect(createdItem.name).toBe('Integration Test Item');
      expect(createdItem.status).toBe('active');
      expect(createdItem.createdAt).toBeDefined();
      expect(createdItem.updatedAt).toBeDefined();

      // Step 2: Read item
      const readEvent = {
        httpMethod: 'GET',
        path: `/items/${createdItemId}`,
        pathParameters: { id: createdItemId },
        headers: {},
      };

      const readResponse = await handler(readEvent as any, {} as any);
      expect(readResponse.statusCode).toBe(200);

      const readItem = JSON.parse(readResponse.body);
      expect(readItem.id).toBe(createdItemId);
      expect(readItem.name).toBe('Integration Test Item');

      // Step 3: Update item
      const updateEvent = {
        httpMethod: 'PUT',
        path: `/items/${createdItemId}`,
        pathParameters: { id: createdItemId },
        body: JSON.stringify({
          name: 'Updated Integration Test Item',
          description: 'Updated description',
          status: 'inactive',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const updateResponse = await handler(updateEvent as any, {} as any);
      expect(updateResponse.statusCode).toBe(200);

      const updatedItem = JSON.parse(updateResponse.body);
      expect(updatedItem.id).toBe(createdItemId);
      expect(updatedItem.name).toBe('Updated Integration Test Item');
      expect(updatedItem.status).toBe('inactive');
      expect(updatedItem.updatedAt).toBeGreaterThanOrEqual(createdItem.updatedAt);

      // Step 4: Delete item
      const deleteEvent = {
        httpMethod: 'DELETE',
        path: `/items/${createdItemId}`,
        pathParameters: { id: createdItemId },
        headers: {},
      };

      const deleteResponse = await handler(deleteEvent as any, {} as any);
      expect(deleteResponse.statusCode).toBe(204);

      // Step 5: Verify item is deleted (should return 404)
      const verifyDeleteEvent = {
        httpMethod: 'GET',
        path: `/items/${createdItemId}`,
        pathParameters: { id: createdItemId },
        headers: {},
      };

      const verifyDeleteResponse = await handler(verifyDeleteEvent as any, {} as any);
      expect(verifyDeleteResponse.statusCode).toBe(404);
    });
  });

  describe('API Gateway Request/Response Transformation', () => {
    it('should properly transform API Gateway event to Lambda response', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          name: 'Test Item',
          description: 'Test',
        }),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'test-client',
        },
        requestContext: {
          requestId: 'test-request-id',
          stage: 'dev',
        },
      };

      const response = await handler(event as any, {} as any);

      // Verify response structure
      expect(response).toHaveProperty('statusCode');
      expect(response).toHaveProperty('headers');
      expect(response).toHaveProperty('body');

      // Verify headers
      expect(response.headers['Content-Type']).toBe('application/json');
      expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();

      // Verify body is valid JSON
      expect(() => JSON.parse(response.body)).not.toThrow();
    });

    it('should include CORS headers in response', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {
          'Origin': 'https://example.com',
        },
      };

      const response = await handler(event as any, {} as any);

      expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
      expect(response.headers['Access-Control-Allow-Methods']).toBeDefined();
      expect(response.headers['Access-Control-Allow-Headers']).toBeDefined();
    });

    it('should handle query string parameters for pagination', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items',
        queryStringParameters: {
          limit: '10',
          offset: '0',
        },
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(200);

      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('items');
      expect(body).toHaveProperty('count');
    });
  });

  describe('Error Propagation Through API Gateway', () => {
    it('should propagate validation errors with 400 status', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          // Missing required 'name' field
          description: 'Test',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(400);

      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('error');
      expect(body).toHaveProperty('message');
    });

    it('should propagate not found errors with 404 status', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items/non-existent-id',
        pathParameters: { id: 'non-existent-id' },
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(404);

      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('error');
    });

    it('should propagate database errors with 500 status', async () => {
      mockDynamoDBClient.simulateError('DynamoDBError');

      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(500);

      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('error');
      expect(body.error).toBe('InternalServerError');
    });

    it('should include request ID in error response', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({}),
        headers: {
          'Content-Type': 'application/json',
        },
        requestContext: {
          requestId: 'test-request-id-123',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body.requestId).toBeDefined();
    });
  });

  describe('List Operation with Pagination', () => {
    it('should return paginated results', async () => {
      // Create multiple items
      for (let i = 0; i < 5; i++) {
        const createEvent = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: `Item ${i}`,
            description: `Description ${i}`,
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        await handler(createEvent as any, {} as any);
      }

      // List with limit
      const listEvent = {
        httpMethod: 'GET',
        path: '/items',
        queryStringParameters: {
          limit: '2',
          offset: '0',
        },
        headers: {},
      };

      const response = await handler(listEvent as any, {} as any);
      expect(response.statusCode).toBe(200);

      const body = JSON.parse(response.body);
      expect(body.items).toBeDefined();
      expect(body.count).toBeDefined();
      expect(body.items.length).toBeLessThanOrEqual(2);
    });
  });

  describe('Concurrent Operations', () => {
    it('should handle concurrent create operations', async () => {
      const createEvents = Array.from({ length: 3 }, (_, i) => ({
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          name: `Concurrent Item ${i}`,
          description: `Concurrent test ${i}`,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      }));

      const responses = await Promise.all(
        createEvents.map((event) => handler(event as any, {} as any))
      );

      responses.forEach((response) => {
        expect(response.statusCode).toBe(201);
        const body = JSON.parse(response.body);
        expect(body.id).toBeDefined();
      });

      // Verify all items have unique IDs
      const ids = responses.map((r) => JSON.parse(r.body).id);
      const uniqueIds = new Set(ids);
      expect(uniqueIds.size).toBe(3);
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty request body for GET requests', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items',
        body: null,
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(200);
    });

    it('should handle malformed JSON in request body', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: 'invalid json {',
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(400);
    });

    it('should handle missing path parameters', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items/undefined',
        pathParameters: null,
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(404);
    });

    it('should handle special characters in item name', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          name: 'Item with special chars: !@#$%^&*()',
          description: 'Test with émojis 🎉',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      expect(response.statusCode).toBe(201);

      const body = JSON.parse(response.body);
      expect(body.name).toContain('!@#$%^&*()');
    });
  });
});
