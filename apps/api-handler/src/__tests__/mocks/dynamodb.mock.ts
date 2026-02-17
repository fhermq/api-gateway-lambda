/**
 * DynamoDB Mock for Integration Tests
 * Simulates DynamoDB operations for testing without AWS credentials
 */

interface MockItem {
  id: string;
  name: string;
  description?: string;
  status: string;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
  version: number;
}

class DynamoDBMock {
  private items: Map<string, MockItem> = new Map();
  private shouldError: boolean = false;
  private errorType: string = '';

  reset(): void {
    this.items.clear();
    this.shouldError = false;
    this.errorType = '';
  }

  simulateError(errorType: string): void {
    this.shouldError = true;
    this.errorType = errorType;
  }

  async getItem(id: string): Promise<MockItem | null> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    const item = this.items.get(id);
    return item || null;
  }

  async putItem(item: MockItem): Promise<void> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    this.items.set(item.id, item);
  }

  async updateItem(id: string, updates: Partial<MockItem>): Promise<MockItem> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    const item = this.items.get(id);
    if (!item) {
      throw new Error('Item not found');
    }

    const updated = {
      ...item,
      ...updates,
      id: item.id, // Ensure ID doesn't change
      createdAt: item.createdAt, // Ensure createdAt doesn't change
      updatedAt: Date.now(),
    };

    this.items.set(id, updated);
    return updated;
  }

  async deleteItem(id: string): Promise<void> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    if (!this.items.has(id)) {
      throw new Error('Item not found');
    }

    this.items.delete(id);
  }

  async scan(): Promise<MockItem[]> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    return Array.from(this.items.values());
  }

  async query(
    indexName: string,
    keyCondition: Record<string, any>
  ): Promise<MockItem[]> {
    if (this.shouldError) {
      throw new Error(`DynamoDB Error: ${this.errorType}`);
    }

    // Simple query implementation for status-index
    if (indexName === 'status-index' && keyCondition.status) {
      return Array.from(this.items.values()).filter(
        (item) => item.status === keyCondition.status
      );
    }

    return [];
  }

  getItemCount(): number {
    return this.items.size;
  }

  getAllItems(): MockItem[] {
    return Array.from(this.items.values());
  }
}

export const mockDynamoDBClient = new DynamoDBMock();

// Mock the DynamoDB utility module
jest.mock('../../utils/dynamodb', () => ({
  getDynamoDBClient: () => mockDynamoDBClient,
  getItem: (id: string) => mockDynamoDBClient.getItem(id),
  putItem: (item: MockItem) => mockDynamoDBClient.putItem(item),
  updateItem: (id: string, updates: Partial<MockItem>) =>
    mockDynamoDBClient.updateItem(id, updates),
  deleteItem: (id: string) => mockDynamoDBClient.deleteItem(id),
  scan: () => mockDynamoDBClient.scan(),
  query: (indexName: string, keyCondition: Record<string, any>) =>
    mockDynamoDBClient.query(indexName, keyCondition),
}));
