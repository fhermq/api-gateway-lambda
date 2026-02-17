// Unit tests for validators
// Property 3: Input Validation Prevents Invalid Operations
// Validates: Requirements 3.8, 13.5

import {
  validateCreateItem,
  validateUpdateItem,
  validateListItems,
} from '../../utils/validators';

describe('Validators', () => {
  describe('Create Item Validation', () => {
    it('should validate correct create request', () => {
      const result = validateCreateItem({
        name: 'Test Item',
        description: 'Test Description',
        status: 'active',
      });

      expect(result.valid).toBe(true);
      expect(result.errors).toBeUndefined();
    });

    it('should reject missing name', () => {
      const result = validateCreateItem({
        description: 'No name',
      });

      expect(result.valid).toBe(false);
      expect(result.errors).toBeDefined();
      expect(result.errors?.[0].field).toContain('name');
    });

    it('should reject empty name', () => {
      const result = validateCreateItem({
        name: '',
      });

      expect(result.valid).toBe(false);
    });

    it('should reject name exceeding max length', () => {
      const result = validateCreateItem({
        name: 'a'.repeat(256),
      });

      expect(result.valid).toBe(false);
    });

    it('should reject invalid status', () => {
      const result = validateCreateItem({
        name: 'Test',
        status: 'invalid',
      });

      expect(result.valid).toBe(false);
    });

    it('should accept valid statuses', () => {
      const statuses = ['active', 'inactive', 'archived'];

      statuses.forEach((status) => {
        const result = validateCreateItem({
          name: 'Test',
          status,
        });

        expect(result.valid).toBe(true);
      });
    });

    it('should reject description exceeding max length', () => {
      const result = validateCreateItem({
        name: 'Test',
        description: 'a'.repeat(1001),
      });

      expect(result.valid).toBe(false);
    });
  });

  describe('Update Item Validation', () => {
    it('should validate correct update request', () => {
      const result = validateUpdateItem({
        name: 'Updated Name',
        status: 'inactive',
      });

      expect(result.valid).toBe(true);
    });

    it('should allow partial updates', () => {
      const result = validateUpdateItem({
        name: 'Updated',
      });

      expect(result.valid).toBe(true);
    });

    it('should allow empty update object', () => {
      const result = validateUpdateItem({});

      expect(result.valid).toBe(true);
    });

    it('should reject invalid status in update', () => {
      const result = validateUpdateItem({
        status: 'unknown',
      });

      expect(result.valid).toBe(false);
    });

    it('should reject empty name in update', () => {
      const result = validateUpdateItem({
        name: '',
      });

      expect(result.valid).toBe(false);
    });
  });

  describe('List Items Validation', () => {
    it('should validate correct list request', () => {
      const result = validateListItems({
        limit: 10,
        offset: 0,
      });

      expect(result.valid).toBe(true);
    });

    it('should allow empty query params', () => {
      const result = validateListItems({});

      expect(result.valid).toBe(true);
    });

    it('should reject negative limit', () => {
      const result = validateListItems({
        limit: -1,
      });

      expect(result.valid).toBe(false);
    });

    it('should reject limit exceeding max', () => {
      const result = validateListItems({
        limit: 101,
      });

      expect(result.valid).toBe(false);
    });

    it('should reject negative offset', () => {
      const result = validateListItems({
        offset: -1,
      });

      expect(result.valid).toBe(false);
    });

    it('should accept valid limit values', () => {
      for (let i = 1; i <= 100; i += 10) {
        const result = validateListItems({ limit: i });
        expect(result.valid).toBe(true);
      }
    });
  });

  describe('Error message format', () => {
    it('should include field name in error', () => {
      const result = validateCreateItem({
        name: '',
      });

      expect(result.errors?.[0].field).toBeDefined();
      expect(result.errors?.[0].message).toBeDefined();
    });

    it('should provide descriptive error messages', () => {
      const result = validateCreateItem({
        name: 'a'.repeat(256),
      });

      expect(result.errors?.[0].message).toContain('max');
    });
  });
});
