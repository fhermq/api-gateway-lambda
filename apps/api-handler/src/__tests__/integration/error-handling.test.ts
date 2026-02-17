import { handler } from '../../index';
import { mockDynamoDBClient } from '../mocks/dynamodb.mock';

/**
 * Integration Tests: Error Handling
 * Tests error responses for various error scenarios
 * Tests CORS headers in responses
 * Tests status code correctness
 * 
 * **Property 2: Lambda Handler Status Codes**
 * **Validates: Requirements 3.6, 3.7, 12.7, 12.8**
 */

describe('Integration: Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockDynamoDBClient.reset();
  });

  describe('HTTP Status Codes', () => {
    describe('2xx Success Codes', () => {
      it('should return 200 for successful GET request', async () => {
        const event = {
          httpMethod: 'GET',
          path: '/items',
          headers: {},
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(200);
      });

      it('should return 201 for successful POST request', async () => {
        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 'New Item',
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(201);
      });

      it('should return 204 for successful DELETE request', async () => {
        // First create an item
        const createEvent = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 'Item to Delete',
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const createResponse = await handler(createEvent as any, {} as any);
        const itemId = JSON.parse(createResponse.body).id;

        // Then delete it
        const deleteEvent = {
          httpMethod: 'DELETE',
          path: `/items/${itemId}`,
          pathParameters: { id: itemId },
          headers: {},
        };

        const deleteResponse = await handler(deleteEvent as any, {} as any);
        expect(deleteResponse.statusCode).toBe(204);
        expect(deleteResponse.body).toBe('');
      });

      it('should return 200 for successful PUT request', async () => {
        // First create an item
        const createEvent = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 'Item to Update',
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const createResponse = await handler(createEvent as any, {} as any);
        const itemId = JSON.parse(createResponse.body).id;

        // Then update it
        const updateEvent = {
          httpMethod: 'PUT',
          path: `/items/${itemId}`,
          pathParameters: { id: itemId },
          body: JSON.stringify({
            name: 'Updated Item',
            description: 'Updated',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const updateResponse = await handler(updateEvent as any, {} as any);
        expect(updateResponse.statusCode).toBe(200);
      });
    });

    describe('4xx Client Error Codes', () => {
      it('should return 400 for missing required fields', async () => {
        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            description: 'Missing name field',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(400);

        const body = JSON.parse(response.body);
        expect(body.error).toBe('ValidationError');
      });

      it('should return 400 for invalid data types', async () => {
        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 123, // Should be string
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(400);
      });

      it('should return 400 for name exceeding max length', async () => {
        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 'a'.repeat(256), // Exceeds 255 char limit
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(400);
      });

      it('should return 400 for malformed JSON', async () => {
        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: '{invalid json}',
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(400);
      });

      it('should return 404 for non-existent item', async () => {
        const event = {
          httpMethod: 'GET',
          path: '/items/non-existent-id',
          pathParameters: { id: 'non-existent-id' },
          headers: {},
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(404);

        const body = JSON.parse(response.body);
        expect(body.error).toBe('NotFoundError');
      });

      it('should return 404 when updating non-existent item', async () => {
        const event = {
          httpMethod: 'PUT',
          path: '/items/non-existent-id',
          pathParameters: { id: 'non-existent-id' },
          body: JSON.stringify({
            name: 'Updated',
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(404);
      });

      it('should return 404 when deleting non-existent item', async () => {
        const event = {
          httpMethod: 'DELETE',
          path: '/items/non-existent-id',
          pathParameters: { id: 'non-existent-id' },
          headers: {},
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(404);
      });
    });

    describe('5xx Server Error Codes', () => {
      it('should return 500 for database errors', async () => {
        mockDynamoDBClient.simulateError('DynamoDBError');

        const event = {
          httpMethod: 'GET',
          path: '/items',
          headers: {},
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(500);

        const body = JSON.parse(response.body);
        expect(body.error).toBe('InternalServerError');
      });

      it('should return 500 for unhandled exceptions', async () => {
        mockDynamoDBClient.simulateError('UnexpectedError');

        const event = {
          httpMethod: 'POST',
          path: '/items',
          body: JSON.stringify({
            name: 'Test',
            description: 'Test',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        };

        const response = await handler(event as any, {} as any);
        expect(response.statusCode).toBe(500);
      });
    });
  });

  describe('CORS Headers', () => {
    it('should include CORS headers in all responses', async () => {
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

    it('should include CORS headers in error responses', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({}),
        headers: {
          'Origin': 'https://example.com',
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);

      expect(response.statusCode).toBe(400);
      expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
    });

    it('should include CORS headers in 404 responses', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items/non-existent',
        pathParameters: { id: 'non-existent' },
        headers: {
          'Origin': 'https://example.com',
        },
      };

      const response = await handler(event as any, {} as any);

      expect(response.statusCode).toBe(404);
      expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
    });

    it('should include CORS headers in 500 responses', async () => {
      mockDynamoDBClient.simulateError('DynamoDBError');

      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {
          'Origin': 'https://example.com',
        },
      };

      const response = await handler(event as any, {} as any);

      expect(response.statusCode).toBe(500);
      expect(response.headers['Access-Control-Allow-Origin']).toBeDefined();
    });

    it('should set correct CORS methods', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {},
      };

      const response = await handler(event as any, {} as any);

      const methods = response.headers['Access-Control-Allow-Methods'];
      expect(methods).toContain('GET');
      expect(methods).toContain('POST');
      expect(methods).toContain('PUT');
      expect(methods).toContain('DELETE');
    });
  });

  describe('Error Response Format', () => {
    it('should include error and message fields', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({}),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body).toHaveProperty('error');
      expect(body).toHaveProperty('message');
      expect(typeof body.error).toBe('string');
      expect(typeof body.message).toBe('string');
    });

    it('should include requestId in error response', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items/non-existent',
        pathParameters: { id: 'non-existent' },
        headers: {},
        requestContext: {
          requestId: 'test-request-id-123',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body.requestId).toBeDefined();
    });

    it('should include timestamp in error response', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({}),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body.timestamp).toBeDefined();
      expect(typeof body.timestamp).toBe('number');
    });

    it('should not expose sensitive information in error messages', async () => {
      mockDynamoDBClient.simulateError('DynamoDBError');

      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      // Should not contain AWS credentials or internal details
      expect(body.message).not.toMatch(/aws_access_key/i);
      expect(body.message).not.toMatch(/aws_secret_key/i);
      expect(body.message).not.toMatch(/password/i);
    });
  });

  describe('Validation Error Details', () => {
    it('should provide specific validation error message', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          description: 'Missing name',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body.message).toContain('name');
      expect(body.message).toContain('required');
    });

    it('should indicate field that failed validation', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({
          name: 'a'.repeat(256),
          description: 'Test',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      const body = JSON.parse(response.body);

      expect(body.message).toContain('name');
    });
  });

  describe('Content-Type Headers', () => {
    it('should return JSON content type for all responses', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items',
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.headers['Content-Type']).toBe('application/json');
    });

    it('should return JSON content type for error responses', async () => {
      const event = {
        httpMethod: 'POST',
        path: '/items',
        body: JSON.stringify({}),
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const response = await handler(event as any, {} as any);
      expect(response.headers['Content-Type']).toBe('application/json');
    });

    it('should return JSON content type for 404 responses', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/items/non-existent',
        pathParameters: { id: 'non-existent' },
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect(response.headers['Content-Type']).toBe('application/json');
    });
  });

  describe('Unsupported Operations', () => {
    it('should return 400 for unsupported HTTP method', async () => {
      const event = {
        httpMethod: 'PATCH',
        path: '/items/123',
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect([400, 405]).toContain(response.statusCode);
    });

    it('should return 400 for invalid path', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/invalid-path',
        headers: {},
      };

      const response = await handler(event as any, {} as any);
      expect([400, 404]).toContain(response.statusCode);
    });
  });
});
