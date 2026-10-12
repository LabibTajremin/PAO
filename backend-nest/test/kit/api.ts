// The real API on a random port, on a private database, Redis prefix and buckets, with a
// fake clock (the Go testkit/api.go). Module agents add their helpers (signIn, ...) in
// files beside this one.
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { type Server } from 'node:http';
import { type AddressInfo } from 'node:net';
import {
  type INestApplication,
  type ModuleMetadata,
  type Provider,
  type Type,
} from '@nestjs/common';
import { Test, type TestingModuleBuilder } from '@nestjs/testing';
import { API_APP_OPTIONS, configureApiApp } from '../../src/app/api-app';
import { AppModule } from '../../src/app/app.module';
import { type AccessClaims, TokenSigner } from '../../src/platform/auth/access-token';
import { CLOCK } from '../../src/platform/clock/clock';
import { FakeClock } from '../../src/platform/clock/fake-clock';
import { type AppConfig } from '../../src/platform/config/app-config';
import { UuidV7Generator } from '../../src/platform/ids/id-generator';
import { createLogger, discardLogger, LOGGER } from '../../src/platform/logging/logger';
import { REDIS_KEYS, type RedisKeys } from '../../src/platform/redis/redis-client';
import { type OpenApiDocument, OPENAPI_DOCUMENT } from '../../src/platform/http/spec-routes';
import { onCleanup, testEnv } from './cleanup';
import { migratedDatabase } from './postgres';
import { testRedis } from './redis';
import { ResponseValidator } from './response-validator';
import { testS3Config } from './storage';

/** A decoded API answer. */
export interface TestResponse {
  readonly status: number;
  readonly headers: Headers;
  readonly text: string;
  /** The JSON body, or undefined when the body is not JSON. */
  readonly body: Record<string, unknown> | undefined;
  /** `error.code` of an error body. */
  readonly code: string | undefined;
}

/** Per-request options of {@link TestApi.do}. */
export interface RequestOptions {
  readonly token?: string;
  readonly headers?: Record<string, string>;
  /** Sends `body` as is instead of JSON-encoding it. */
  readonly raw?: boolean;
  /** Skips the response-contract check, for answers a spec deliberately breaks. */
  readonly unchecked?: boolean;
}

/** What a spec can change about the app it starts. */
export interface TestApiOptions {
  /** Controllers registered ahead of the catch-all, e.g. fixtures of an edge spec. */
  readonly controllers?: Type[];
  /** Extra modules, e.g. a global stand-in for a contract whose module is not ported yet. */
  readonly imports?: ModuleMetadata['imports'];
  /** Extra providers on the root module, e.g. stand-ins for module seams. */
  readonly providers?: Provider[];
  /** Replaces the contract, e.g. with a fixture document. */
  readonly document?: OpenApiDocument;
  /** Further provider overrides. */
  readonly override?: (b: TestingModuleBuilder) => TestingModuleBuilder;
  /** Changes the configuration before the app is built. */
  readonly config?: Partial<AppConfig>;
}

/** A complete test configuration on the PAO_TEST_* services. */
export async function testConfig(): Promise<AppConfig> {
  const { privateKey } = generateKeyPairSync('ed25519');
  return {
    appEnv: 'test',
    logLevel: 'debug',
    httpAddr: '127.0.0.1:0',
    metricsAddr: '127.0.0.1:0',
    databaseUrl: await migratedDatabase(),
    redisUrl: testEnv('PAO_TEST_REDIS_URL'),
    s3: testS3Config(),
    jwt: { keyId: 'k1', signingKey: privateKey, previousKeys: new Map() },
    dataEncryptionKey: randomBytes(32),
    adminCorsOrigin: 'http://admin',
    smsAdapter: 'console',
    sslWireless: { apiToken: '', sid: '' },
    pushAdapter: 'log',
    fcmCredentialsFile: '',
    seedAdminPassword: '',
  };
}

/** A running API for one spec file. */
export class TestApi {
  readonly signer: TokenSigner;
  private readonly responses: ResponseValidator;

  readonly app: INestApplication;
  readonly url: string;
  readonly config: AppConfig;
  readonly clock: FakeClock;
  readonly keys: RedisKeys;

  constructor(parts: {
    app: INestApplication;
    url: string;
    config: AppConfig;
    clock: FakeClock;
    keys: RedisKeys;
  }) {
    ({
      app: this.app,
      url: this.url,
      config: this.config,
      clock: this.clock,
      keys: this.keys,
    } = parts);
    const { config, clock, app } = parts;
    this.signer = new TokenSigner(
      { keyId: config.jwt.keyId, key: config.jwt.signingKey, ttlMs: 15 * 60_000 },
      clock,
      new UuidV7Generator(),
    );
    this.responses = new ResponseValidator(app.get(OPENAPI_DOCUMENT));
  }

  /** Sends a request; checks the answer against the contract unless told not to. */
  async do(method: string, path: string, body?: unknown, opts: RequestOptions = {}) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', ...opts.headers };
    if (opts.token !== undefined) {
      headers.Authorization = `Bearer ${opts.token}`;
    }
    const payload =
      body === undefined || opts.raw ? (body as string | undefined) : JSON.stringify(body);
    const res = await fetch(this.url + path, { method, headers, body: payload });
    const text = await res.text();
    const json = parseJson(text);
    const problem = opts.unchecked
      ? undefined
      : this.responses.check(method, path, res.status, json);
    if (problem !== undefined) {
      throw new Error(`response breaks the contract: ${problem}\n${text}`);
    }
    const error = json?.error as { code?: string } | undefined;
    return { status: res.status, headers: res.headers, text, body: json, code: error?.code };
  }

  /** Signs an access token for any subject and roles, bypassing sign-in. */
  async token(subject: string, roles: string[], sessionId?: string): Promise<string> {
    return (await this.claims(subject, roles, sessionId)).token;
  }

  /** Like {@link token}, also returning the claims. */
  claims(
    subject: string,
    roles: string[],
    sessionId?: string,
  ): Promise<{ token: string; claims: AccessClaims }> {
    return this.signer.sign({ subject, roles, sessionId });
  }
}

function parseJson(text: string): Record<string, unknown> | undefined {
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return undefined;
  }
}

/** Builds and starts the API with every module, closed when the spec file ends. */
export async function startTestApi(opts: TestApiOptions = {}): Promise<TestApi> {
  const config = { ...(await testConfig()), ...opts.config };
  const { keys } = await testRedis();
  const clock = new FakeClock(new Date());
  // PAO_TEST_LOG=1 shows server logs, e.g. the cause behind a 500.
  const log = process.env.PAO_TEST_LOG ? createLogger('debug') : discardLogger();
  let builder = Test.createTestingModule({
    imports: [AppModule.forRoot(config), ...(opts.imports ?? [])],
    controllers: opts.controllers ?? [],
    providers: opts.providers ?? [],
  })
    .overrideProvider(CLOCK)
    .useValue(clock)
    .overrideProvider(REDIS_KEYS)
    .useValue(keys)
    .overrideProvider(LOGGER)
    .useValue(log);
  if (opts.document) {
    builder = builder.overrideProvider(OPENAPI_DOCUMENT).useValue(opts.document);
  }
  builder = opts.override ? opts.override(builder) : builder;
  const app = (await builder.compile()).createNestApplication(API_APP_OPTIONS);
  await configureApiApp(app);
  await app.listen(0, '127.0.0.1');
  onCleanup(() => app.close());
  const { port } = (app.getHttpServer() as Server).address() as AddressInfo;
  return new TestApi({ app, url: `http://127.0.0.1:${port}`, config, clock, keys });
}
