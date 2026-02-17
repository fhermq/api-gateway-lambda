// Input validation utilities

import * as Joi from 'joi';
import { CreateItemRequest, UpdateItemRequest, ListItemsRequest } from '../types';

const itemNameSchema = Joi.string().min(1).max(255).required();
const itemDescriptionSchema = Joi.string().max(1000).optional();
const itemStatusSchema = Joi.string().valid('active', 'inactive', 'archived').optional();

export const createItemSchema = Joi.object<CreateItemRequest>({
  name: itemNameSchema,
  description: itemDescriptionSchema,
  status: itemStatusSchema,
});

export const updateItemSchema = Joi.object<UpdateItemRequest>({
  name: itemNameSchema.optional(),
  description: itemDescriptionSchema,
  status: itemStatusSchema,
});

export const listItemsSchema = Joi.object<ListItemsRequest>({
  limit: Joi.number().min(1).max(100).optional(),
  offset: Joi.number().min(0).optional(),
});

export interface ValidationError {
  field: string;
  message: string;
}

export function validateCreateItem(data: unknown): { valid: boolean; errors?: ValidationError[] } {
  const { error, value } = createItemSchema.validate(data, { abortEarly: false });

  if (error) {
    const errors: ValidationError[] = error.details.map((detail) => ({
      field: detail.path.join('.'),
      message: detail.message,
    }));
    return { valid: false, errors };
  }

  return { valid: true };
}

export function validateUpdateItem(data: unknown): { valid: boolean; errors?: ValidationError[] } {
  const { error, value } = updateItemSchema.validate(data, { abortEarly: false });

  if (error) {
    const errors: ValidationError[] = error.details.map((detail) => ({
      field: detail.path.join('.'),
      message: detail.message,
    }));
    return { valid: false, errors };
  }

  return { valid: true };
}

export function validateListItems(data: unknown): { valid: boolean; errors?: ValidationError[] } {
  const { error, value } = listItemsSchema.validate(data, { abortEarly: false });

  if (error) {
    const errors: ValidationError[] = error.details.map((detail) => ({
      field: detail.path.join('.'),
      message: detail.message,
    }));
    return { valid: false, errors };
  }

  return { valid: true };
}
