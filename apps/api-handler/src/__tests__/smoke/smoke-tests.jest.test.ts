import { SmokeTestRunner, SmokeTestConfig } from './smoke-tests';

/**
 * Jest-compatible Smoke Tests
 * These tests are designed to run in Jest and validate post-deployment functionality
 * 
 * To run these tests against a deployed environment:
 * API_GATEWAY_URL=https://api.example.com npm test -- smoke-tests.jest.test.ts
 * 
 * Requirements: 9.6, 15.5
 */

describe('Smoke Tests - Post-Deployment Validation', () => {
  let runner: SmokeTestRunner;

  beforeAll(() => {
    const config: SmokeTestConfig = {
      apiGatewayUrl: process.env.API_GATEWAY_URL || 'http://localhost:3000',
      lambdaFunctionName: process.env.LAMBDA_FUNCTION_NAME || 'api-handler-dev',
      dynamodbTableName: process.env.DYNAMODB_TABLE_NAME || 'items-dev',
      awsRegion: process.env.AWS_REGION || 'us-east-1',
      environment: process.env.ENVIRONMENT || 'dev',
    };

    runner = new SmokeTestRunner(config);
  });

  describe('API Gateway', () => {
    it('should be accessible and responding', async () => {
      const result = await runner.testApiGatewayAccessibility();
      expect(result).toBe(true);
    });

    it('should return correct response format', async () => {
      const result = await runner.testApiResponseFormat();
      expect(result).toBe(true);
    });

    it('should include CORS headers', async () => {
      const result = await runner.testCorsHeadersPresent();
      expect(result).toBe(true);
    });

    it('should include Content-Type headers', async () => {
      const result = await runner.testContentTypeHeaders();
      expect(result).toBe(true);
    });

    it('should respond within acceptable time', async () => {
      const result = await runner.testResponseTime();
      expect(result).toBe(true);
    });
  });

  describe('Lambda Function', () => {
    it('should be invoked successfully', async () => {
      const result = await runner.testLambdaFunctionInvocation();
      expect(result).toBe(true);
    });

    it('should handle errors correctly', async () => {
      const result = await runner.testErrorHandling();
      expect(result).toBe(true);
    });
  });

  describe('DynamoDB', () => {
    it('should be accessible and working', async () => {
      const result = await runner.testDynamodbTableAccessibility();
      expect(result).toBe(true);
    });
  });

  describe('CloudWatch', () => {
    it('should be logging requests', async () => {
      const result = await runner.testCloudwatchLogsWritten();
      expect(result).toBe(true);
    });
  });

  describe('CRUD Operations', () => {
    it('should support all CRUD operations', async () => {
      const result = await runner.testCrudOperations();
      expect(result).toBe(true);
    });
  });
});
