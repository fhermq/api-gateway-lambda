// Read item handler

import { Item, ApiResponse, ApiError } from '../types';
import { Logger } from '../utils/logger';
import { dbClient } from '../utils/dynamodb';

export async function readItem(
  id: string,
  requestId: string,
): Promise<ApiResponse<Item | ApiError>> {
  const logger = new Logger(requestId);

  try {
    logger.info('Reading item', { itemId: id });

    const item = await dbClient.get(id);

    if (!item) {
      logger.warn('Item not found', { itemId: id });
      return {
        statusCode: 404,
        body: {
          error: 'NotFound',
          message: `Item with id ${id} not found`,
          requestId,
          timestamp: Date.now(),
        },
      };
    }

    logger.info('Item retrieved successfully', { itemId: id });
    return {
      statusCode: 200,
      body: item,
    };
  } catch (error) {
    logger.error('Failed to read item', { error: String(error), itemId: id });
    return {
      statusCode: 500,
      body: {
        error: 'InternalServerError',
        message: 'Failed to read item',
        requestId,
        timestamp: Date.now(),
      },
    };
  }
}
