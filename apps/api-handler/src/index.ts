// Lambda handler entry point

import { APIGatewayProxyHandler, APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { Logger } from './utils/logger';
import { createItem } from './handlers/create';
import { readItem } from './handlers/read';
import { listItems } from './handlers/list';
import { updateItem } from './handlers/update';
import { deleteItem } from './handlers/delete';

const handler: APIGatewayProxyHandler = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  const requestId = event.requestContext.requestId;
  const logger = new Logger(requestId);

  try {
    logger.info('Received request', {
      method: event.httpMethod,
      path: event.path,
      pathParameters: event.pathParameters,
      queryStringParameters: event.queryStringParameters,
    });

    const { httpMethod, path, pathParameters, queryStringParameters, body } = event;

    // Parse body if present
    let parsedBody: unknown;
    if (body) {
      try {
        parsedBody = JSON.parse(body);
      } catch (error) {
        logger.error('Failed to parse request body', { error: String(error) });
        return {
          statusCode: 400,
          body: JSON.stringify({
            error: 'BadRequest',
            message: 'Invalid JSON in request body',
            requestId,
            timestamp: Date.now(),
          }),
        };
      }
    }

    let response;

    // Route to appropriate handler
    if (httpMethod === 'POST' && path === '/items') {
      response = await createItem(parsedBody, requestId);
    } else if (httpMethod === 'GET' && path === '/items') {
      response = await listItems(queryStringParameters, requestId);
    } else if (httpMethod === 'GET' && path.startsWith('/items/')) {
      const id = pathParameters?.id;
      if (!id) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            error: 'BadRequest',
            message: 'Missing item id',
            requestId,
            timestamp: Date.now(),
          }),
        };
      }
      response = await readItem(id, requestId);
    } else if (httpMethod === 'PUT' && path.startsWith('/items/')) {
      const id = pathParameters?.id;
      if (!id) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            error: 'BadRequest',
            message: 'Missing item id',
            requestId,
            timestamp: Date.now(),
          }),
        };
      }
      response = await updateItem(id, parsedBody, requestId);
    } else if (httpMethod === 'DELETE' && path.startsWith('/items/')) {
      const id = pathParameters?.id;
      if (!id) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            error: 'BadRequest',
            message: 'Missing item id',
            requestId,
            timestamp: Date.now(),
          }),
        };
      }
      response = await deleteItem(id, requestId);
    } else {
      logger.warn('Route not found', { method: httpMethod, path });
      return {
        statusCode: 404,
        body: JSON.stringify({
          error: 'NotFound',
          message: 'Route not found',
          requestId,
          timestamp: Date.now(),
        }),
      };
    }

    logger.info('Request completed', { statusCode: response.statusCode });

    return {
      statusCode: response.statusCode,
      body: JSON.stringify(response.body),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    };
  } catch (error) {
    logger.error('Unhandled error', { error: String(error) });
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'InternalServerError',
        message: 'An unexpected error occurred',
        requestId,
        timestamp: Date.now(),
      }),
    };
  }
};

export { handler };
