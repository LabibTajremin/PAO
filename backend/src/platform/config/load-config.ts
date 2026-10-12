import { type KeyObject } from 'node:crypto';
import { z } from 'zod';
import { ED25519_KEY_BYTES, privateKeyFromSeed, publicKeyFromRaw } from '../auth/ed25519';
import { type AppConfig } from './app-config';
import { decodeBase64, key, logLevel, oneOf, optional, required } from './env-schema';

/** The environment as a lookup of variable name to value. */
export type Environment = Readonly<Record<string, string | undefined>>;

const previousKeys = optional('').transform((list, ctx) => {
  const keys = new Map<string, KeyObject>();
  for (const pair of list.split(',').filter((p) => p !== '')) {
    const [kid = '', encoded = ''] = pair.split(/:(.*)/s);
    const raw = decodeBase64(encoded);
    if (kid === '' || raw?.length !== ED25519_KEY_BYTES) {
      ctx.addIssue({
        code: 'custom',
        message: `JWT_PREVIOUS_PUBLIC_KEYS entry "${kid}" must be kid:base64-public-key`,
      });
      continue;
    }
    keys.set(kid, publicKeyFromRaw(raw));
  }
  return keys;
});

const envSchema = z.object({
  APP_ENV: oneOf('APP_ENV', ['dev', 'test', 'staging', 'prod']),
  LOG_LEVEL: logLevel('LOG_LEVEL'),
  HTTP_ADDR: optional(':8080'),
  METRICS_ADDR: optional(':9090'),
  DATABASE_URL: required('DATABASE_URL'),
  REDIS_URL: required('REDIS_URL'),
  S3_ENDPOINT: required('S3_ENDPOINT'),
  S3_PUBLIC_ENDPOINT: optional(''),
  S3_REGION: optional('us-east-1'),
  S3_ACCESS_KEY: required('S3_ACCESS_KEY'),
  S3_SECRET_KEY: required('S3_SECRET_KEY'),
  S3_BUCKET_PRIVATE: required('S3_BUCKET_PRIVATE'),
  S3_BUCKET_PUBLIC: required('S3_BUCKET_PUBLIC'),
  JWT_KEY_ID: optional('k1'),
  JWT_SIGNING_KEY: key('JWT_SIGNING_KEY', ED25519_KEY_BYTES),
  JWT_PREVIOUS_PUBLIC_KEYS: previousKeys,
  DATA_ENCRYPTION_KEY: key('DATA_ENCRYPTION_KEY', 32),
  ADMIN_CORS_ORIGIN: optional('http://localhost:5000'),
  SMS_ADAPTER: oneOf('SMS_ADAPTER', ['console', 'sslwireless']),
  PUSH_ADAPTER: oneOf('PUSH_ADAPTER', ['log', 'fcm']),
  SEED_ADMIN_PASSWORD: optional(''),
});

type ParsedEnv = z.infer<typeof envSchema>;

/** Thrown when the environment is incomplete or invalid; lists every problem at once. */
export class ConfigError extends Error {
  constructor(readonly problems: readonly string[]) {
    super('invalid configuration: ' + problems.join('; '));
    this.name = 'ConfigError';
  }
}

/** Requirements that depend on other variables, checked on the raw environment. */
function conditionalProblems(env: Environment): string[] {
  const problems: string[] = [];
  const need = (name: string): void => {
    if ((env[name] ?? '') === '') {
      problems.push(`${name} is required`);
    }
  };
  if (env.SMS_ADAPTER === 'sslwireless') {
    need('SSLWIRELESS_API_TOKEN');
    need('SSLWIRELESS_SID');
  }
  if (env.PUSH_ADAPTER === 'fcm') {
    need('FCM_CREDENTIALS_FILE');
  }
  const fakeSms = (env.SMS_ADAPTER ?? '') === '' || env.SMS_ADAPTER === 'console';
  const fakePush = (env.PUSH_ADAPTER ?? '') === '' || env.PUSH_ADAPTER === 'log';
  if (env.APP_ENV === 'prod' && (fakeSms || fakePush)) {
    problems.push('production needs real SMS_ADAPTER and PUSH_ADAPTER');
  }
  return problems;
}

function toConfig(e: ParsedEnv, env: Environment): AppConfig {
  return {
    appEnv: e.APP_ENV,
    logLevel: e.LOG_LEVEL,
    httpAddr: e.HTTP_ADDR,
    metricsAddr: e.METRICS_ADDR,
    databaseUrl: e.DATABASE_URL,
    redisUrl: e.REDIS_URL,
    s3: {
      endpoint: e.S3_ENDPOINT,
      publicEndpoint: e.S3_PUBLIC_ENDPOINT === '' ? e.S3_ENDPOINT : e.S3_PUBLIC_ENDPOINT,
      region: e.S3_REGION,
      accessKey: e.S3_ACCESS_KEY,
      secretKey: e.S3_SECRET_KEY,
      bucketPrivate: e.S3_BUCKET_PRIVATE,
      bucketPublic: e.S3_BUCKET_PUBLIC,
    },
    jwt: {
      keyId: e.JWT_KEY_ID,
      signingKey: privateKeyFromSeed(e.JWT_SIGNING_KEY),
      previousKeys: e.JWT_PREVIOUS_PUBLIC_KEYS,
    },
    dataEncryptionKey: e.DATA_ENCRYPTION_KEY,
    adminCorsOrigin: e.ADMIN_CORS_ORIGIN,
    smsAdapter: e.SMS_ADAPTER,
    sslWireless: {
      apiToken: env.SSLWIRELESS_API_TOKEN ?? '',
      sid: env.SSLWIRELESS_SID ?? '',
    },
    pushAdapter: e.PUSH_ADAPTER,
    fcmCredentialsFile: env.FCM_CREDENTIALS_FILE ?? '',
    seedAdminPassword: e.SEED_ADMIN_PASSWORD,
  };
}

/** Reads and validates the configuration (process.env in the entry points). */
export function loadConfig(env: Environment): AppConfig {
  const parsed = envSchema.safeParse(env);
  const problems = parsed.success ? [] : parsed.error.issues.map((i) => i.message);
  problems.push(...conditionalProblems(env));
  if (!parsed.success || problems.length > 0) {
    throw new ConfigError(problems);
  }
  return toConfig(parsed.data, env);
}
