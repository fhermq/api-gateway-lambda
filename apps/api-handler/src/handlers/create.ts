// Create item handler

import { v4 as uuidv4 } from 'uuid';
import { Item, CreateItemRequest, ApiResponse, ApiError } from '../types';
import { Logger } from '../utils/logger';
import { dbClient } from '../utils/dynamodb';
import { validateCreateItem } from '../utils/validators';

export async function createItem(
  body: unknown,
  requestId: string,
): Promise<ApiResponse<Item | ApiError>> {
  const logger = new Logger(requestId);

  try {
    logger.info('Creating new item', { body });

    // Validate input
    const validation = validateCreateItem(body);
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

    const request = body as CreateItemRequest;
    const now = Date.now();

    const item: Item = {
      id: uuidv4(),
      name: request.name,
      description: request.description,
      status: request.status || 'active',
      createdAt: now,
      updatedAt: now,
      createdBy: 'system',
      version: 1,
    };

    // Save to DynamoDB
    const savedItem = await dbClient.put(item);
    logger.info('Item created successfully', { itemId: savedItem.id });

    return {
      statusCode: 201,
      body: savedItem,
    };
  } catch (error) {
    logger.error('Failed to create item', { error: String(error) });
    return {
      statusCode: 500,
      body: {
        error: 'InternalServerError',
        message: 'Failed to create item',
        requestId,
        timestamp: Date.now(),
      },
    };
  }
}
