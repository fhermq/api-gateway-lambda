// List items handler

import { ListItemsResponse, ApiResponse, ApiError } from '../types';
import { Logger } from '../utils/logger';
import { dbClient } from '../utils/dynamodb';
import { validateListItems } from '../utils/validators';

export async function listItems(
  queryParams: unknown,
  requestId: string,
): Promise<ApiResponse<ListItemsResponse | ApiError>> {
  const logger = new Logger(requestId);

  try {
    logger.info('Listing items', { queryParams });

    // Validate query parameters
    const validation = validateListItems(queryParams);
    if (!validation.valid) {
      logger.warn('Validation failed', { errors: validation.errors });
      return {
        statusCode: 400,
        body: {
          error: 'ValidationError',
          message: 'Invalid query parameters',
          requestId,
          timestamp: Date.now(),
        },
      };
    }

    const params = queryParams as { limit?: number; offset?: number };
    const { items, count } = await dbClient.scan(params.limit, params.offset);

    logger.info('Items retrieved successfully', { count });
    return {
      statusCode: 200,
      body: {
        items,
        count,
      },
    };
  } catch (error) {
    logger.error('Failed to list items', { error: String(error) });
    return {
      statusCode: 500,
      body: {
        error: 'InternalServerError',
        message: 'Failed to list items',
        requestId,
        timestamp: Date.now(),
      },
    };
  }
}
