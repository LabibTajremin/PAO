/**
 * An API error: the HTTP status, the stable `ErrorCode` the apps translate and a message
 * (PRD §9.6). Instances are immutable; `withDetails` and `wrap` return copies.
 */
export class ApiError extends Error {
  readonly details?: Readonly<Record<string, unknown>>;
  readonly retryAfterMs: number;

  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    extra: ApiErrorExtra = {},
  ) {
    super(message, { cause: extra.cause });
    this.name = 'ApiError';
    this.details = extra.details;
    this.retryAfterMs = extra.retryAfterMs ?? 0;
  }

  /** A copy with `details` attached. */
  withDetails(details: Readonly<Record<string, unknown>>): ApiError {
    return new ApiError(this.status, this.code, this.message, { ...this.extra(), details });
  }

  /** A copy that remembers the underlying error for logs. */
  wrap(cause: unknown): ApiError {
    return new ApiError(this.status, this.code, this.message, { ...this.extra(), cause });
  }

  private extra(): ApiErrorExtra {
    return { details: this.details, retryAfterMs: this.retryAfterMs, cause: this.cause };
  }
}

/** Optional parts of an {@link ApiError}. */
export interface ApiErrorExtra {
  readonly details?: Readonly<Record<string, unknown>>;
  /** For 429: how long the client should wait; sent as Retry-After in seconds. */
  readonly retryAfterMs?: number;
  readonly cause?: unknown;
}

/** No valid session; the app signs in again. */
export const UNAUTHENTICATED = new ApiError(401, 'UNAUTHENTICATED', 'Sign in again.');
/** The access token expired; the app refreshes it. */
export const TOKEN_EXPIRED = new ApiError(401, 'TOKEN_EXPIRED', 'Session expired.');
/** The caller lacks the permission. */
export const FORBIDDEN = new ApiError(
  403,
  'FORBIDDEN',
  'You do not have permission for this action.',
);
/** Unknown route or resource. */
export const NOT_FOUND = new ApiError(404, 'NOT_FOUND', 'Not found.');
/** A known route called with the wrong method; the code stays NOT_FOUND as in the Go API. */
export const METHOD_NOT_ALLOWED = new ApiError(405, 'NOT_FOUND', 'Method not allowed.');
/** The request breaks the contract. */
export const VALIDATION_FAILED = new ApiError(422, 'VALIDATION_FAILED', 'Invalid request.');
/** Anything unexpected; the cause is logged, never sent. */
export const INTERNAL = new ApiError(500, 'INTERNAL', 'Something went wrong.');
/** A spec operation no module serves yet. */
export const NOT_IMPLEMENTED = new ApiError(501, 'NOT_IMPLEMENTED', 'Not available yet.');

/** A 429 that tells the client when to retry. */
export function rateLimited(code: string, retryAfterMs: number): ApiError {
  return new ApiError(429, code, 'Too many requests. Try again later.', { retryAfterMs });
}
