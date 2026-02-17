// Delete item handler

import { ApiResponse, ApiError } from '../types';
import { Logger } from '../utils/logger';
import { dbClient } from '../utils/dynamodb';

export async function deleteItem(
  id: string,
  requestId: string,
): Promise<ApiResponse<null | ApiError>> {
  const logger = new Logger(requestId);

  try {
    logger.info('Deleting item', { itemId: id });

    // Check if item exists
    const existingItem = await dbClient.get(id);
    if (!existingItem) {
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

    await dbClient.delete(id);
    logger.info('Item deleted successfully', { itemId: id });

    return {
      statusCode: 204,
      body: null,
    };
  } catch (error) {
    logger.error('Failed to delete item', { error: String(error), itemId: id });
    return {
      statusCode: 500,
      body: {
        error: 'InternalServerError',
        message: 'Failed to delete item',
        requestId,
        timestamp: Date.now(),
      },
    };
  }
}
