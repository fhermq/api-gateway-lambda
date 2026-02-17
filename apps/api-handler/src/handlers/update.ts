// Update item handler

import { Item, UpdateItemRequest, ApiResponse, ApiError } from '../types';
import { Logger } from '../utils/logger';
import { dbClient } from '../utils/dynamodb';
import { validateUpdateItem } from '../utils/validators';

export async function updateItem(
  id: string,
  body: unknown,
  requestId: string,
): Promise<ApiResponse<Item | ApiError>> {
  const logger = new Logger(requestId);

  try {
    logger.info('Updating item', { itemId: id, body });

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

    // Validate input
    const validation = validateUpdateItem(body);
    if (!validation.valid) {
      logger.warn('Validation failed', { errors: validation.errors });
      return {
        statusCode: 400,
        body: {
          error: 'ValidationError',
          message: 'Invalid request body',
          requestId,
          timestamp: Date.now(),
        },
      };
    }

    const request = body as UpdateItemRequest;
    const updates: Partial<Item> = {
      ...request,
      updatedAt: Date.now(),
      version: existingItem.version + 1,
    };

    const updatedItem = await dbClient.update(id, updates);
    logger.info('Item updated successfully', { itemId: id });

    return {
      statusCode: 200,
      body: updatedItem,
    };
  } catch (error) {
    logger.error('Failed to update item', { error: String(error), itemId: id });
    return {
      statusCode: 500,
      body: {
        error: 'InternalServerError',
        message: 'Failed to update item',
        requestId,
        timestamp: Date.now(),
      },
    };
  }
}
