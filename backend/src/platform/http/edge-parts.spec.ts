import { EventEmitter } from 'node:events';
import { type ServerResponse } from 'node:http';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { type ExecutionContext } from '@nestjs/common';
import { lastValueFrom, of, throwError } from 'rxjs';
import { DomainError } from '../errors/domain-error';
import { discardLogger } from '../logging/logger';
import { ApiError, INTERNAL, NOT_FOUND, UNAUTHENTICATED, VALIDATION_FAILED } from './api-error';
import { type ApiRequest } from './api-request';
import { isPrivateAddress, normalizeIp, proxiedClientIp } from './client-ip';
import { DEFAULT_PAGE_SIZE, decodeCursor, encodeCursor, MAX_PAGE_SIZE, pageSize } from './cursor';
import { bodyReaderMiddleware, MAX_BODY_BYTES } from './edge-middleware';
import { errorBody, StoredResponse, toApiError, writeError } from './error-response';
import { mapError, MapErrorsInterceptor } from './map-errors';
import { hasRole, type Principal } from './principal';
import { principalOf } from './request-decorators';

describe('ApiError', () => {
  it('copies with details or a cause and builds the envelope', () => {
    const cause = new Error('db');
    const e = VALIDATION_FAILED.withDetails({ field: 'phone' }).wrap(cause);
    expect(e).toBeInstanceOf(ApiError);
    expect(e.cause).toBe(cause);
    expect(errorBody(e)).toEqual({
      error: {
        code: 'VALIDATION_FAILED',
        message: 'Invalid request.',
        details: { field: 'phone' },
      },
    });
    expect(errorBody(VALIDATION_FAILED.withDetails({}))).toEqual({
      error: { code: 'VALIDATION_FAILED', message: 'Invalid request.' },
    });
  });
});

describe('toApiError', () => {
  it('maps Nest exceptions and hides anything else', () => {
    expect(toApiError(NOT_FOUND)).toBe(NOT_FOUND);
    expect(toApiError(new NotFoundException()).code).toBe('NOT_FOUND');
    expect(toApiError(new BadRequestException()).code).toBe('VALIDATION_FAILED');
    expect(toApiError(new ConflictException()).code).toBe('INTERNAL');
    expect(toApiError(new Error('x')).code).toBe(INTERNAL.code);
  });
});

function fakeResponse(headersSent = false) {
  const written: { status?: number; headers: Record<string, string>; body?: unknown } = {
    headers: {},
  };
  const res = {
    headersSent,
    setHeader: (k: string, v: string) => (written.headers[k] = v),
    writeHead: (status: number, headers: Record<string, string>) => {
      written.status = status;
      Object.assign(written.headers, headers);
    },
    end: (body?: unknown) => (written.body = body),
  } as unknown as ServerResponse;
  return { res, written };
}

describe('writeError', () => {
  it('replays stored answers and stops after a started response', () => {
    const replay = fakeResponse();
    writeError(replay.res, new StoredResponse(201, Buffer.from('{}')), discardLogger());
    expect(replay.written).toMatchObject({
      status: 201,
      headers: { 'Idempotent-Replayed': 'true' },
    });
    const started = fakeResponse(true);
    writeError(started.res, new Error('late'), discardLogger(), '/x');
    expect(started.written.status).toBeUndefined();
  });
});

describe('mapError and MapErrorsInterceptor', () => {
  const map = { 'booking.not_found': NOT_FOUND };

  it('maps reasons anywhere in the cause chain and leaves others', async () => {
    const wrapped = new Error('ctx', { cause: new DomainError('booking.not_found') });
    expect((mapError(map, wrapped) as ApiError).code).toBe('NOT_FOUND');
    const other = new DomainError('booking.other');
    expect(mapError(map, other)).toBe(other);
    expect(mapError(map, 'text')).toBe('text');
    const interceptor = new MapErrorsInterceptor(map);
    const ctx = {} as ExecutionContext;
    await expect(
      lastValueFrom(interceptor.intercept(ctx, { handle: () => throwError(() => wrapped) })),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    expect(await lastValueFrom(interceptor.intercept(ctx, { handle: () => of(1) }))).toBe(1);
  });
});

describe('principal', () => {
  it('reads roles and requires a principal', () => {
    const p: Principal = {
      accountId: 'a',
      roles: ['customer'],
      tokenId: 'j',
      sessionId: 's',
      expiresAt: new Date(0),
    };
    expect(hasRole(p, 'customer')).toBe(true);
    expect(hasRole(p, 'provider')).toBe(false);
    expect(principalOf({ principal: p } as ApiRequest)).toBe(p);
    expect(() => principalOf({} as ApiRequest)).toThrow(UNAUTHENTICATED);
  });
});

describe('client IP', () => {
  it.each([
    ['10.0.0.5', '1.2.3.4, 203.0.113.9', '203.0.113.9'],
    ['203.0.113.50', '1.2.3.4', '203.0.113.50'],
    ['10.0.0.5', undefined, '10.0.0.5'],
    ['10.0.0.5', 'garbage', '10.0.0.5'],
    ['::1', ['1.1.1.1', '::ffff:8.8.8.8'], '8.8.8.8'],
    ['not-an-ip', '1.1.1.1', 'not-an-ip'],
  ])('peer %s with %j is %s', (peer, xff, want) => {
    expect(proxiedClientIp(peer, xff)).toBe(want);
  });

  it('knows private networks and IPv4-mapped addresses', () => {
    expect(isPrivateAddress('fd00::1')).toBe(true);
    expect(isPrivateAddress('172.20.0.1')).toBe(true);
    expect(isPrivateAddress('8.8.8.8')).toBe(false);
    expect(normalizeIp('::ffff:127.0.0.1')).toBe('127.0.0.1');
    expect(proxiedClientIp('10.0.0.5', [])).toBe('10.0.0.5');
  });
});

describe('cursor', () => {
  it('round-trips and treats an empty cursor as the first page', () => {
    const id = '0199c4f0-0000-7000-8000-000000000001';
    const s = encodeCursor({ createdAt: new Date('2026-10-09T10:00:00Z'), id });
    expect(decodeCursor(s)).toEqual({ createdAt: '2026-10-09T10:00:00.000Z', id });
    const micro = encodeCursor({ createdAt: '2026-10-09T10:00:00.123456Z', id });
    expect(decodeCursor(micro)?.createdAt).toBe('2026-10-09T10:00:00.123456Z');
    expect(decodeCursor('')).toBeUndefined();
    expect(decodeCursor(undefined)).toBeUndefined();
  });

  it.each([
    '%%%',
    'bm90LWpzb24',
    'e30',
    'bnVsbA',
    Buffer.from('{"t":"x","i":"0199c4f0-0000-7000-8000-000000000001"}').toString('base64url'),
    Buffer.from('{"t":"2026-10-09T10:00:00Z","i":"00000000-0000-0000-0000-000000000000"}').toString(
      'base64url',
    ),
  ])('rejects %s', (bad) => {
    expect(() => decodeCursor(bad)).toThrow(ApiError);
  });

  it.each([
    [undefined, 20],
    [0, 20],
    [500, 100],
    [30, 30],
  ])('page size for %s is %s', (limit, want) => {
    expect(pageSize(limit)).toBe(want);
    expect([DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE]).toEqual([20, 100]);
  });
});

describe('bodyReaderMiddleware', () => {
  it('records a stream that fails', () => {
    const req = Object.assign(new EventEmitter(), { headers: {} }) as unknown as ApiRequest;
    let called = 0;
    bodyReaderMiddleware(req, {} as never, () => called++);
    req.emit('error', new Error('reset'));
    expect(req.bodyError).toBe('request body could not be read');
    expect(MAX_BODY_BYTES).toBe(1024 * 1024);
    expect(called).toBe(1);
  });
});
