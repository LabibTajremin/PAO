import { EventEmitter } from 'node:events';
import { type CallHandler, type ExecutionContext } from '@nestjs/common';
import { type Response } from 'express';
import { of } from 'rxjs';
import { ACCESS_TOKEN_TTL_MS } from '../auth/auth.module';
import { createLogger } from '../logging/logger';
import { IDEMPOTENCY_TTL_MS, type IdempotencyStore } from '../redis/idempotency-store';
import { RedisKeys } from '../redis/redis-client';
import { type ApiRequest } from './api-request';
import { IdempotencyInterceptor } from './idempotency.interceptor';
import { OPENAPI_DOCUMENT_PATH } from './spec-routes';

function call(res: EventEmitter): ExecutionContext {
  const req = {
    method: 'POST',
    path: '/v1/customer/bookings',
    headers: { 'idempotency-key': 'key-12345' },
    operation: { idempotent: true },
    principal: { accountId: 'a1' },
  } as unknown as ApiRequest;
  return {
    switchToHttp: () => ({ getRequest: () => req, getResponse: () => res }),
  } as unknown as ExecutionContext;
}

describe('IdempotencyInterceptor', () => {
  it('logs when the answer cannot be stored', async () => {
    const logged: string[] = [];
    const log = createLogger('error', {
      write: (line: string) => logged.push(line),
    });
    const store = {
      reserve: () => Promise.resolve({ reserved: true, record: { requestHash: 'h', done: false } }),
      complete: () => Promise.reject(new Error('redis down')),
    } as unknown as IdempotencyStore;
    const interceptor = new IdempotencyInterceptor(store, new RedisKeys('t'), log);
    const res = Object.assign(new EventEmitter(), {
      statusCode: 201,
      writableFinished: true,
      end: () => res,
    }) as unknown as Response & EventEmitter;
    const next: CallHandler = { handle: () => of({}) };
    await interceptor.intercept(call(res), next);
    res.end(Buffer.from('{}'));
    res.end();
    res.emit('close');
    await new Promise((r) => setImmediate(r));
    expect(logged.join('')).toContain('idempotency bookkeeping failed');
  });

  it('keeps answers a day, while access tokens live 15 minutes', () => {
    expect(IDEMPOTENCY_TTL_MS).toBe(24 * 3600 * 1000);
    expect(ACCESS_TOKEN_TTL_MS).toBe(15 * 60 * 1000);
    expect(OPENAPI_DOCUMENT_PATH).toMatch(/src\/platform\/http\/openapi\.gen\.yaml$/);
  });
});
