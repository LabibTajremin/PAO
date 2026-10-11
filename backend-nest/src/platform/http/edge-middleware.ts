import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import { type NextFunction, type Request, type Response } from 'express';
import { runWithRequestContext } from '../logging/request-context';
import { type ApiRequest } from './api-request';

/** Request bodies above this size are refused; files go straight to storage (02-architecture §7). */
export const MAX_BODY_BYTES = 1 << 20;

const REQUEST_ID = /^[A-Za-z0-9._-]{8,64}$/;

/** Propagates a well-formed X-Request-ID or issues one, and logs every line with it. */
export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const sent = req.headers['x-request-id'];
  const id = typeof sent === 'string' && REQUEST_ID.test(sent) ? sent : randomUUID();
  res.setHeader('X-Request-ID', id);
  runWithRequestContext({ requestId: id }, next);
}

/** Sets the security headers of 02-architecture §7 on every response. */
export function securityHeadersMiddleware(_req: Request, res: Response, next: NextFunction): void {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
}

/** Allows only the admin web origin, with credentials for its refresh cookie. */
export function corsMiddleware(origin: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (req.headers.origin === origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
      res.setHeader(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type, Idempotency-Key, X-Request-ID',
      );
      res.setHeader('Access-Control-Max-Age', '600');
      res.appendHeader('Vary', 'Origin');
    }
    if (req.method === 'OPTIONS' && req.headers['access-control-request-method'] !== undefined) {
      res.status(204).end();
      return;
    }
    next();
  };
}

/**
 * Reads the body (at most {@link MAX_BODY_BYTES}) and parses JSON. Problems are recorded,
 * not answered, because request validation reports them after authentication, as the Go
 * API did.
 */
export function bodyReaderMiddleware(req: ApiRequest, _res: Response, next: NextFunction): void {
  // Stream events run outside the request's logging context; carry it over explicitly.
  const proceed = AsyncLocalStorage.bind(next);
  const chunks: Buffer[] = [];
  let size = 0;
  req.on('data', (chunk: Buffer) => {
    size += chunk.length;
    if (size <= MAX_BODY_BYTES) {
      chunks.push(chunk);
    }
  });
  req.on('error', () => {
    req.bodyError = 'request body could not be read';
    proceed();
  });
  req.on('end', () => {
    if (size > MAX_BODY_BYTES) {
      req.bodyError = 'request body too large';
      proceed();
      return;
    }
    req.rawBody = Buffer.concat(chunks);
    req.body = parseJson(req);
    proceed();
  });
}

function parseJson(req: ApiRequest): unknown {
  if (req.rawBody?.length === 0) {
    return undefined;
  }
  try {
    return JSON.parse(String(req.rawBody)) as unknown;
  } catch {
    if (/^application\/json\b/i.test(req.headers['content-type'] ?? '')) {
      req.bodyError = 'request body is not valid JSON';
    }
    return undefined;
  }
}
