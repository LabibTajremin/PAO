import { type ServerResponse } from 'node:http';
import { HttpException } from '@nestjs/common';
import { type Logger } from '../logging/logger';
import {
  ApiError,
  FORBIDDEN,
  INTERNAL,
  NOT_FOUND,
  UNAUTHENTICATED,
  VALIDATION_FAILED,
} from './api-error';

/** A stored answer to send again unchanged (idempotent replays). */
export class StoredResponse extends Error {
  constructor(
    readonly status: number,
    readonly body: Buffer,
  ) {
    super('replay stored response');
    this.name = 'StoredResponse';
  }
}

// Nest raises its own HttpExceptions for a few framework-level failures.
const FRAMEWORK_ERRORS: Readonly<Record<number, ApiError>> = {
  400: VALIDATION_FAILED,
  401: UNAUTHENTICATED,
  403: FORBIDDEN,
  404: NOT_FOUND,
  422: VALIDATION_FAILED,
};

/** Returns the API error to send for `err`; anything unexpected becomes 500 INTERNAL. */
export function toApiError(err: unknown): ApiError {
  if (err instanceof ApiError) {
    return err;
  }
  if (err instanceof HttpException) {
    return (FRAMEWORK_ERRORS[err.getStatus()] ?? INTERNAL).wrap(err);
  }
  return INTERNAL.wrap(err);
}

/** The error envelope of PRD §9.6: `{"error":{"code","message","details?"}}`. */
export function errorBody(e: ApiError): { error: Record<string, unknown> } {
  const body: Record<string, unknown> = { code: e.code, message: e.message };
  if (e.details && Object.keys(e.details).length > 0) {
    body.details = e.details;
  }
  return { error: body };
}

/**
 * Writes `err` in the single error format. Server errors are logged with their cause;
 * the cause never reaches the client.
 */
export function writeError(res: ServerResponse, err: unknown, log: Logger, path?: string): void {
  if (res.headersSent) {
    log.error({ err, path }, 'error after the response started');
    res.end();
    return;
  }
  if (err instanceof StoredResponse) {
    res.writeHead(err.status, {
      'Content-Type': 'application/json',
      'Idempotent-Replayed': 'true',
    });
    res.end(err.body);
    return;
  }
  const apiError = toApiError(err);
  if (apiError.status >= 500) {
    log.error({ err: apiError.cause ?? apiError, path }, 'unhandled error');
  }
  if (apiError.retryAfterMs > 0) {
    res.setHeader('Retry-After', String(Math.floor(apiError.retryAfterMs / 1000)));
  }
  res.writeHead(apiError.status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(errorBody(apiError)) + '\n');
}
