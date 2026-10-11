import { createHash } from 'node:crypto';
import {
  type CallHandler,
  type ExecutionContext,
  Inject,
  Injectable,
  type NestInterceptor,
} from '@nestjs/common';
import { type Response } from 'express';
import { type Observable } from 'rxjs';
import { LOGGER, type Logger } from '../logging/logger';
import { IdempotencyStore } from '../redis/idempotency-store';
import { REDIS_KEYS, type RedisKeys } from '../redis/redis-client';
import { ApiError } from './api-error';
import { type ApiRequest } from './api-request';
import { StoredResponse } from './error-response';

const KEY_REUSED = new ApiError(
  422,
  'IDEMPOTENCY_KEY_REUSED',
  'This Idempotency-Key was used for a different request.',
);
const STILL_RUNNING = new ApiError(
  409,
  'CONFLICT',
  'The first request with this key is still running.',
);

/** Fingerprints a request: method, path and body, so a reused key with another body is caught. */
export function requestHash(method: string, path: string, body: Buffer): string {
  return createHash('sha256').update(`${method} ${path}\n`).update(body).digest('hex');
}

/**
 * Replays the first answer for a repeated `Idempotency-Key` on operations that declare
 * the header (PRD §9.6). Answers below 500, including errors, are stored for 24 hours; a
 * server error frees the key so the client can retry.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(
    @Inject(IdempotencyStore) private readonly store: IdempotencyStore,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
    @Inject(LOGGER) private readonly log: Logger,
  ) {}

  async intercept(ctx: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    const req = ctx.switchToHttp().getRequest<ApiRequest>();
    const idempotencyKey = req.headers['idempotency-key'];
    if (req.operation?.idempotent && req.principal && typeof idempotencyKey === 'string') {
      const key = this.keys.key('idem', req.principal.accountId, idempotencyKey);
      const hash = requestHash(req.method, req.path, req.rawBody ?? Buffer.alloc(0));
      await this.claim(key, hash);
      this.remember(ctx.switchToHttp().getResponse<Response>(), key, hash);
    }
    return next.handle();
  }

  /** Claims the key for this request, or throws what a repeat must answer instead. */
  private async claim(key: string, hash: string): Promise<void> {
    const { reserved, record } = await this.store.reserve(key, hash);
    if (reserved) {
      return;
    }
    if (record.requestHash !== hash) {
      throw KEY_REUSED;
    }
    if (!record.done) {
      throw STILL_RUNNING;
    }
    throw new StoredResponse(record.status ?? 200, record.body ?? Buffer.alloc(0));
  }

  /**
   * Records the answer as it is sent, whichever layer sends it (controller or error
   * filter). Every answer of this API is written by a single `end` call.
   */
  private remember(res: Response, key: string, hash: string): void {
    let body = Buffer.alloc(0);
    const end = res.end.bind(res);
    res.end = ((chunk?: unknown, ...rest: unknown[]) => {
      if (typeof chunk === 'string' || Buffer.isBuffer(chunk)) {
        body = Buffer.from(chunk);
      }
      return end(chunk as string, ...(rest as [BufferEncoding]));
    }) as Response['end'];
    res.once('close', () => {
      void this.finish(res, key, hash, body);
    });
  }

  private async finish(res: Response, key: string, hash: string, body: Buffer): Promise<void> {
    try {
      if (!res.writableFinished || res.statusCode >= 500) {
        await this.store.release(key);
      } else {
        await this.store.complete(key, { requestHash: hash, status: res.statusCode, body });
      }
    } catch (err) {
      this.log.error({ err }, 'idempotency bookkeeping failed');
    }
  }
}
