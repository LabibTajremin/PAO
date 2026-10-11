import { type KeyObject } from 'node:crypto';

/** The deployment environment (APP_ENV). */
export type AppEnv = 'dev' | 'test' | 'staging' | 'prod';

/** The minimum level written by the logger (LOG_LEVEL). */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

/** Object storage settings. `publicEndpoint` is what devices reach; inside Docker it differs. */
export interface S3Config {
  readonly endpoint: string;
  readonly publicEndpoint: string;
  readonly region: string;
  readonly accessKey: string;
  readonly secretKey: string;
  readonly bucketPrivate: string;
  readonly bucketPublic: string;
}

/** The access-token signing key and the public keys still accepted during rotation. */
export interface JwtConfig {
  readonly keyId: string;
  readonly signingKey: KeyObject;
  readonly previousKeys: ReadonlyMap<string, KeyObject>;
}

/** The production SMS gateway credentials. */
export interface SslWirelessConfig {
  readonly apiToken: string;
  readonly sid: string;
}

/** Everything the API, the worker and the migrator read from the environment. */
export interface AppConfig {
  readonly appEnv: AppEnv;
  readonly logLevel: LogLevel;
  readonly httpAddr: string;
  readonly metricsAddr: string;
  readonly databaseUrl: string;
  readonly redisUrl: string;
  readonly s3: S3Config;
  readonly jwt: JwtConfig;
  /** AES-256 key for encrypted fields (NID numbers, TOTP secrets). */
  readonly dataEncryptionKey: Buffer;
  readonly adminCorsOrigin: string;
  readonly smsAdapter: 'console' | 'sslwireless';
  readonly sslWireless: SslWirelessConfig;
  readonly pushAdapter: 'log' | 'fcm';
  readonly fcmCredentialsFile: string;
  readonly seedAdminPassword: string;
}

/** Injection token for the {@link AppConfig}. */
export const APP_CONFIG = Symbol('AppConfig');

/** The configuration fields safe to log; secrets never appear. */
export function configLogFields(c: AppConfig): Record<string, string> {
  return {
    app_env: c.appEnv,
    http_addr: c.httpAddr,
    sms_adapter: c.smsAdapter,
    push_adapter: c.pushAdapter,
    jwt_key_id: c.jwt.keyId,
  };
}
