import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { parse } from 'yaml';
import { startTestApi, type TestApi } from '../../../test/kit/api';
import { DomainError } from '../errors/domain-error';
import { HEALTH_ROUTES } from '../health/health';
import { Denylist } from '../redis/denylist';
import { IdempotencyStore } from '../redis/idempotency-store';
import { ApiError } from './api-error';
import { requestHash } from './idempotency.interceptor';
import { MapErrors } from './map-errors';
import { Authenticated, Public, RequirePermission } from './permissions';
import { type Principal } from './principal';
import { ClientIp, CurrentPrincipal } from './request-decorators';
import { checkRoutesAgainstSpec } from './route-spec-check';
import { type OpenApiDocument } from './spec-routes';

const FIXTURE = parse(`
openapi: 3.1.0
info: {title: fixture, version: "1"}
paths:
  /v1/things:
    post:
      operationId: createThing
      x-permission: booking:create
      parameters:
        - {name: Idempotency-Key, in: header, required: true, schema: {type: string, minLength: 8}}
      requestBody:
        required: true
        content:
          application/json:
            schema: {$ref: '#/components/schemas/NewThing'}
      responses:
        "201": {description: ok, content: {application/json: {schema: {type: object}}}}
        "422": {$ref: '#/components/responses/Problem'}
    get:
      operationId: listThings
      parameters:
        - {name: limit, in: query, schema: {type: integer, minimum: 1}}
      responses: {"200": {description: ok}}
  /v1/things/{id}:
    get:
      operationId: getThing
      x-permission: authenticated
      parameters:
        - {name: id, in: path, required: true, schema: {type: string, format: uuid}}
        - {name: limit, in: query, schema: {type: integer}}
      responses: {"200": {description: ok}}
  /v1/open:
    get:
      operationId: openThing
      x-permission: public
      responses: {"200": {description: ok}}
  /v1/undecorated:
    get:
      operationId: undecoratedThing
      x-permission: public
      responses: {"200": {description: ok}}
  /v1/broken:
    get:
      operationId: brokenThing
      x-permission: public
      parameters:
        - {name: kind, in: query, required: true, schema: {type: string, enum: [domain, other, boom]}}
      responses: {"200": {description: ok}}
components:
  schemas:
    NewThing: {type: object, required: [n], properties: {n: {type: integer, minimum: 1}}}
    ErrorResponse: {type: object, required: [error]}
  responses:
    Problem:
      description: problem
      content: {application/json: {schema: {$ref: '#/components/schemas/ErrorResponse'}}}
`) as OpenApiDocument;

let created = 0;

@Controller('v1')
class FixtureController {
  @Post('things')
  @RequirePermission('booking:create')
  @HttpCode(201)
  create(@Body() body: { n: number }, @CurrentPrincipal() p: Principal) {
    created++;
    if (body.n === 13) {
      throw new ApiError(422, 'VALIDATION_FAILED', 'Unlucky.');
    }
    if (body.n === 500) {
      throw new Error('db down');
    }
    return { n: body.n, by: p.accountId, call: created };
  }

  @Get('things/:id')
  @Authenticated()
  get(@Param('id') id: string, @Query('limit') limit: unknown, @CurrentPrincipal() p: Principal) {
    return { id, limit, roles: p.roles, session: p.sessionId };
  }

  @Get('open')
  @Public()
  open(@ClientIp() ip: string) {
    return { ip };
  }

  @Get('undecorated')
  undecorated() {
    return { reached: true };
  }

  @Get('broken')
  @Public()
  @MapErrors({ 'thing.gone': new ApiError(404, 'NOT_FOUND', 'Gone.') })
  broken(@Query('kind') kind: string) {
    if (kind === 'domain') {
      throw new Error('wrapped', { cause: new DomainError('thing.gone') });
    }
    throw kind === 'other' ? new DomainError('thing.other') : new Error('boom');
  }
}

describe('HTTP edge over a fixture contract', () => {
  let api: TestApi;
  let customer: string;
  let provider: string;
  const customerId = uuidv4();

  beforeAll(async () => {
    api = await startTestApi({ document: FIXTURE, controllers: [FixtureController] });
    customer = await api.token(customerId, ['customer']);
    provider = await api.token(uuidv4(), ['provider']);
  });

  it('denies a route without a permission decorator, and an operation without x-permission', async () => {
    expect((await api.do('GET', '/v1/undecorated')).code).toBe('UNAUTHENTICATED');
    const decorated = await api.do('GET', '/v1/undecorated', undefined, { token: customer });
    expect(decorated).toMatchObject({ status: 403, code: 'FORBIDDEN' });
    const spec = await api.do('GET', '/v1/things', undefined, { token: customer });
    expect(spec).toMatchObject({ status: 403, code: 'FORBIDDEN' });
  });

  it('enforces RBAC permissions from the identity tables', async () => {
    const body = { n: 1 };
    const headers = { 'Idempotency-Key': 'key-provider-1' };
    const refused = await api.do('POST', '/v1/things', body, { token: provider, headers });
    expect(refused).toMatchObject({ status: 403, code: 'FORBIDDEN' });
    const revoked = await api.claims(uuidv4(), ['customer']);
    await api.app.get(Denylist).deny(revoked.claims.tokenId, 60_000);
    const denied = await api.do('GET', `/v1/things/${uuidv4()}`, undefined, {
      token: revoked.token,
    });
    expect(denied.code).toBe('UNAUTHENTICATED');
  });

  it('coerces parameters and passes the principal and client IP', async () => {
    const id = uuidv4();
    const r = await api.do('GET', `/v1/things/${id}?limit=5`, undefined, { token: customer });
    expect(r.body).toEqual({
      id,
      limit: 5,
      roles: ['customer'],
      session: '00000000-0000-0000-0000-000000000000',
    });
    const bad = await api.do('GET', '/v1/things/not-a-uuid', undefined, { token: customer });
    expect(bad.code).toBe('VALIDATION_FAILED');
    expect((await api.do('GET', '/v1/open')).body).toEqual({ ip: '127.0.0.1' });
    const proxied = await api.do('GET', '/v1/open', undefined, {
      headers: { 'X-Forwarded-For': '1.2.3.4, 203.0.113.9' },
    });
    expect(proxied.body).toEqual({ ip: '203.0.113.9' });
  });

  it('replays an idempotent request and refuses a reused key', async () => {
    const opts = { token: customer, headers: { 'Idempotency-Key': 'key-12345' } };
    const first = await api.do('POST', '/v1/things', { n: 2 }, opts);
    expect(first).toMatchObject({ status: 201, body: { n: 2, by: customerId } });
    const replay = await api.do('POST', '/v1/things', { n: 2 }, opts);
    expect(replay.status).toBe(201);
    expect(replay.text).toBe(first.text);
    expect(replay.headers.get('idempotent-replayed')).toBe('true');
    const reused = await api.do('POST', '/v1/things', { n: 3 }, opts);
    expect(reused).toMatchObject({ status: 422, code: 'IDEMPOTENCY_KEY_REUSED' });
    const key = api.keys.key('idem', customerId, 'key-12345');
    const stored = await api.app.get(IdempotencyStore).reserve(key, 'x');
    expect(stored.record.status).toBe(201);
  });

  it('stores client errors, frees the key after a server error, and skips invalid requests', async () => {
    const headers = (k: string) => ({ token: customer, headers: { 'Idempotency-Key': k } });
    const unlucky = await api.do('POST', '/v1/things', { n: 13 }, headers('key-unlucky'));
    expect(unlucky.status).toBe(422);
    const again = await api.do('POST', '/v1/things', { n: 13 }, headers('key-unlucky'));
    expect(again.headers.get('idempotent-replayed')).toBe('true');
    const crash = await api.do('POST', '/v1/things', { n: 500 }, headers('key-crash'));
    expect(crash).toMatchObject({ status: 500, code: 'INTERNAL' });
    const before = created;
    const retry = await api.do('POST', '/v1/things', { n: 500 }, headers('key-crash'));
    expect(retry.status).toBe(500);
    expect(created).toBe(before + 1);
    const invalid = await api.do('POST', '/v1/things', { n: 0 }, headers('key-invalid'));
    expect(invalid.code).toBe('VALIDATION_FAILED');
    const valid = await api.do('POST', '/v1/things', { n: 4 }, headers('key-invalid'));
    expect(valid.status).toBe(201);
    const missing = await api.do('POST', '/v1/things', { n: 4 }, { token: customer });
    expect(missing.code).toBe('VALIDATION_FAILED');
  });

  it('answers 409 while the first request with a key still runs', async () => {
    const key = api.keys.key('idem', customerId, 'key-running');
    const hash = requestHash('POST', '/v1/things', Buffer.from('{"n":7}'));
    await api.app.get(IdempotencyStore).reserve(key, hash);
    const r = await api.do(
      'POST',
      '/v1/things',
      { n: 7 },
      {
        token: customer,
        headers: { 'Idempotency-Key': 'key-running' },
      },
    );
    expect(r).toMatchObject({ status: 409, code: 'CONFLICT' });
  });

  it('maps domain errors with @MapErrors and hides everything else', async () => {
    expect(await api.do('GET', '/v1/broken?kind=domain')).toMatchObject({
      status: 404,
      body: { error: { code: 'NOT_FOUND', message: 'Gone.' } },
    });
    expect((await api.do('GET', '/v1/broken?kind=other')).code).toBe('INTERNAL');
    const boom = await api.do('GET', '/v1/broken?kind=boom');
    expect(boom).toMatchObject({ status: 500, code: 'INTERNAL' });
    expect(boom.text).not.toContain('boom');
  });

  it('reports bodies that are too large or not JSON', async () => {
    const opts = { token: customer, headers: { 'Idempotency-Key': 'key-large' }, raw: true };
    const large = await api.do('POST', '/v1/things', 'x'.repeat((1 << 20) + 1), opts);
    expect(large.code).toBe('VALIDATION_FAILED');
    expect(large.text).toContain('request body too large');
    const text = await api.do('POST', '/v1/things', 'n=1', {
      ...opts,
      headers: { 'Idempotency-Key': 'key-text', 'Content-Type': 'text/plain' },
    });
    expect(text.code).toBe('VALIDATION_FAILED');
  });

  it('lets a route-to-contract check find drift', () => {
    // Business modules' routes are undocumented in the fixture contract; look only at
    // the fixture's own paths and the health routes.
    const ours = (route: string) => /\/v1\/(things|undecorated)|\/(healthz|readyz)$/.test(route);
    const report = checkRoutesAgainstSpec(api.app, FIXTURE, HEALTH_ROUTES);
    expect(report.mismatched).toEqual(['GET /v1/undecorated: decorator undefined, spec public']);
    expect(report.undocumented.filter(ours)).toEqual([]);
    expect(report.unserved).toEqual(['GET /v1/things listThings']);
    expect(checkRoutesAgainstSpec(api.app, FIXTURE).undocumented.filter(ours)).toEqual([
      'GET /healthz',
      'GET /readyz',
    ]);
  });
});
