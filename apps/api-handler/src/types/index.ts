// Type definitions for the API Handler

export interface Item {
  id: string;
  name: string;
  description?: string;
  status: 'active' | 'inactive' | 'archived';
  createdAt: number;
  updatedAt: number;
  createdBy: string;
  version: number;
}

export interface CreateItemRequest {
  name: string;
  description?: string;
  status?: 'active' | 'inactive' | 'archived';
}

export interface UpdateItemRequest {
  name?: string;
  description?: string;
  status?: 'active' | 'inactive' | 'archived';
}

export interface ListItemsRequest {
  limit?: number;
  offset?: number;
}

export interface ListItemsResponse {
  items: Item[];
  count: number;
  nextToken?: string;
}

export interface ApiResponse<T> {
  statusCode: number;
  body: T;
  headers?: Record<string, string>;
}

export interface ApiError {
  error: string;
  message: string;
  requestId: string;
  timestamp: number;
}

export interface LambdaEvent {
  httpMethod: string;
  path: string;
  pathParameters?: Record<string, string>;
  queryStringParameters?: Record<string, string>;
  body?: string;
  requestContext: {
    requestId: string;
  };
}

export interface LambdaContext {
  requestId: string;
  functionName: string;
  functionVersion: string;
  invokedFunctionArn: string;
  memoryLimitInMB: string;
  awsRequestId: string;
  logGroupName: string;
  logStreamName: string;
}
