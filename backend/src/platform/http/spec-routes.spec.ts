import { createServer } from 'node:http';
import { type ExecutionContext } from '@nestjs/common';
import { parse } from 'yaml';
import { type TokenVerifier, TokenInvalidError } from '../auth/access-token';
import { HEALTH_ROUTES, HealthController, readiness } from '../health/health';
import { probe } from '../health/probe';
import { type Denylist } from '../redis/denylist';
import { type RateLimiter } from '../redis/rate-limiter';
import { RedisKeys } from '../redis/redis-client';
import { type RbacChecker } from '../rbac/rbac';
import { NOT_IMPLEMENTED } from './api-error';
import { AuthenticationGuard, AuthorizationGuard, RateLimitGuard } from './guards';
import { closeServer, listen } from './listen';
import { RequestValidator } from './request-validator';
import {
  encodePointer,
  loadOpenApiDocument,
  resolveRef,
  SpecRoutes,
  type OpenApiDocument,
} from './spec-routes';
import { UnimplementedController } from './unimplemented.module';
import { RequirePermission } from './permissions';

const DOC = parse(`
paths:
  /v1/things/{id}:
    parameters:
      - {name: id, in: path, required: true, schema: {type: string}}
    get:
      operationId: getThing
      parameters:
        - {$ref: '#/components/parameters/Session'}
        - {name: X-Trace, in: header, required: true, schema: {type: string}}
    put:
      operationId: putThing
      requestBody:
        content:
          application/json:
            schema: {type: object}
  /v1/things/queue:
    get: {operationId: thingQueue}
components:
  parameters:
    Session: {name: session, in: cookie, required: true, schema: {type: string, minLength: 3}}
`) as OpenApiDocument;

describe('SpecRoutes', () => {
  const routes = new SpecRoutes(DOC);

  it('prefers literal paths and decodes parameters', () => {
    expect(routes.match('GET', '/v1/things/queue')).toMatchObject({ id: 'thingQueue' });
    expect(routes.match('GET', '/v1/things/a%20b')).toMatchObject({ pathParams: { id: 'a b' } });
    expect(routes.match('GET', '/v1/things/%zz')).toMatchObject({ pathParams: { id: '%zz' } });
    expect(routes.match('POST', '/v1/things/queue')).toBe('method_not_allowed');
    expect(routes.match('GET', '/v1/nothing')).toBe('not_found');
    expect(routes.operations()).toHaveLength(3);
  });

  it('refuses a template parameter the operation does not declare', () => {
    const broken = { paths: { '/x/{id}': { get: {} } } } as OpenApiDocument;
    expect(() => new SpecRoutes(broken)).toThrow('path parameter id is not declared');
  });

  it('resolves local references only', () => {
    expect(resolveRef(DOC, { $ref: 'http://elsewhere#/x' })).toEqual({
      $ref: 'http://elsewhere#/x',
    });
    expect(resolveRef(DOC, null)).toBeNull();
    expect(encodePointer('/a~b')).toBe('~1a~0b');
    expect(Object.keys(loadOpenApiDocument().paths).length).toBeGreaterThan(100);
  });
});

describe('RequestValidator', () => {
  const routes = new SpecRoutes(DOC);
  const validator = new RequestValidator(DOC);
  const get = routes.match('GET', '/v1/things/1');
  const put = routes.match('PUT', '/v1/things/1');
  const base = {
    path: { id: '1' },
    query: {},
    headers: { 'x-trace': 't' },
    cookies: { session: 'abc' },
  };

  it('checks header and cookie parameters', () => {
    if (typeof get === 'string') {
      throw new Error('no match');
    }
    expect(validator.check(get, base)).toBeUndefined();
    expect(validator.check(get, { ...base, headers: {} })).toContain(
      "must have required property 'x-trace'",
    );
    expect(validator.check(get, { ...base, cookies: { session: 'a' } })).toContain(
      'cookies/session',
    );
  });

  it('lets an optional body be absent but checks its media type', () => {
    if (typeof put === 'string') {
      throw new Error('no match');
    }
    expect(validator.check(put, base)).toBeUndefined();
    const xml = { ...base, rawBody: Buffer.from('<x/>'), contentType: 'application/xml' };
    expect(validator.check(put, xml)).toContain('Content-Type has unexpected value');
    const none = { ...base, rawBody: Buffer.from('{}') };
    expect(validator.check(put, none)).toContain('""');
  });
});

function context(perm: (() => void) | undefined, req: object): ExecutionContext {
  class Target {
    readonly name = 'fixture';
  }
  const handler = (): void => undefined;
  if (perm) {
    RequirePermission('booking:create')(handler);
  }
  return {
    getHandler: () => handler,
    getClass: () => Target,
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
}

describe('guards', () => {
  it('turn a bad token into 401 and a denylist failure into an error', async () => {
    const invalid = {
      verify: () => Promise.reject(new TokenInvalidError()),
    } as unknown as TokenVerifier;
    const guard = new AuthenticationGuard(invalid, {} as Denylist);
    const req = { headers: { authorization: 'Bearer x' } };
    await expect(guard.canActivate(context(() => undefined, req))).rejects.toMatchObject({
      status: 401,
    });
    const anonymous = context(() => undefined, { headers: { authorization: 'Basic x' } });
    await expect(guard.canActivate(anonymous)).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });

  it('require a principal for permissions and skip rate limits off the contract', async () => {
    const authz = new AuthorizationGuard({} as RbacChecker);
    await expect(authz.canActivate(context(() => undefined, {}))).rejects.toMatchObject({
      status: 401,
    });
    const limiter = new RateLimitGuard({} as RateLimiter, new RedisKeys('t'), {
      perUser: 1,
      perIp: 1,
      windowMs: 1,
    });
    expect(await limiter.canActivate(context(undefined, {}))).toBe(true);
  });
});

describe('health', () => {
  it('names the dependencies that fail', async () => {
    expect(await readiness({ db: () => Promise.resolve() })).toEqual({
      status: 200,
      body: { status: 'ok' },
    });
    const down = await readiness({
      db: () => Promise.resolve(),
      redis: () => Promise.reject(new Error('x')),
    });
    expect(down).toEqual({
      status: 503,
      body: { checks: { redis: 'unavailable' }, status: 'unavailable' },
    });
    expect(new HealthController({}).liveness()).toEqual({ status: 'ok' });
    expect(HEALTH_ROUTES.map((r) => r.path)).toEqual(['/healthz', '/readyz']);
  });

  it('probes a URL like the container health check', async () => {
    const server = createServer((req, res) => res.writeHead(req.url === '/ok' ? 200 : 503).end());
    const { port } = await listen(server, '127.0.0.1:0');
    await expect(probe(`http://127.0.0.1:${port}/ok`, 1000)).resolves.toBeUndefined();
    await expect(probe(`http://127.0.0.1:${port}/down`, 1000)).rejects.toThrow('status 503');
    await closeServer(server, 1000);
    await expect(probe(`http://127.0.0.1:${port}/ok`, 1000)).rejects.toThrow('probe');
  });
});

describe('UnimplementedController', () => {
  it('answers 501', () => {
    expect(() => new UnimplementedController().notImplemented()).toThrow(NOT_IMPLEMENTED);
  });
});
