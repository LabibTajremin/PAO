import { Test } from '@nestjs/testing';
import { APP_CONFIG, type AppConfig, configLogFields } from './app-config';
import { ConfigModule } from './config.module';
import { ConfigError, type Environment, loadConfig } from './load-config';

const seed = Buffer.alloc(32).toString('base64');

function validEnv(): Record<string, string> {
  return {
    DATABASE_URL: 'postgres://x',
    REDIS_URL: 'redis://x',
    S3_ENDPOINT: 'http://s3',
    S3_ACCESS_KEY: 'a',
    S3_SECRET_KEY: 'b',
    S3_BUCKET_PRIVATE: 'p',
    S3_BUCKET_PUBLIC: 'q',
    JWT_SIGNING_KEY: seed,
    DATA_ENCRYPTION_KEY: seed,
  };
}

function problemsOf(env: Environment): string {
  try {
    loadConfig(env);
  } catch (err) {
    expect(err).toBeInstanceOf(ConfigError);
    return (err as Error).message;
  }
  throw new Error('expected a configuration error');
}

describe('loadConfig', () => {
  it('fills defaults from a minimal environment', () => {
    const c = loadConfig(validEnv());
    expect(c.appEnv).toBe('dev');
    expect(c.httpAddr).toBe(':8080');
    expect(c.metricsAddr).toBe(':9090');
    expect(c.s3.publicEndpoint).toBe('http://s3');
    expect(c.s3.region).toBe('us-east-1');
    expect(c.logLevel).toBe('info');
    expect(c.jwt.keyId).toBe('k1');
    expect(c.jwt.signingKey.asymmetricKeyType).toBe('ed25519');
    expect(c.adminCorsOrigin).toBe('http://localhost:5000');
    expect(c.smsAdapter).toBe('console');
    expect(c.pushAdapter).toBe('log');
    expect(c.dataEncryptionKey).toHaveLength(32);
    expect(c.seedAdminPassword).toBe('');
  });

  it('treats empty variables as unset', () => {
    const c = loadConfig({ ...validEnv(), APP_ENV: '', S3_PUBLIC_ENDPOINT: '' });
    expect(c.appEnv).toBe('dev');
    expect(c.s3.publicEndpoint).toBe('http://s3');
  });

  it('reports every missing variable at once', () => {
    const message = problemsOf({});
    for (const name of [
      'DATABASE_URL',
      'REDIS_URL',
      'S3_ENDPOINT',
      'JWT_SIGNING_KEY',
      'DATA_ENCRYPTION_KEY',
    ]) {
      expect(message).toContain(name);
    }
    expect(message.startsWith('invalid configuration: ')).toBe(true);
  });

  it.each<[string, Record<string, string>]>([
    ['bad env', { APP_ENV: 'qa' }],
    ['bad level', { LOG_LEVEL: 'loud' }],
    ['short key', { DATA_ENCRYPTION_KEY: 'c2hvcnQ=' }],
    ['not base64', { JWT_SIGNING_KEY: '%%%' }],
    ['bad previous', { JWT_PREVIOUS_PUBLIC_KEYS: 'k0:nope' }],
    ['previous without kid', { JWT_PREVIOUS_PUBLIC_KEYS: ':' + seed }],
    ['sms creds', { SMS_ADAPTER: 'sslwireless' }],
    ['fcm creds', { PUSH_ADAPTER: 'fcm' }],
    ['prod fake sms', { APP_ENV: 'prod' }],
  ])('rejects %s', (_name, overrides) => {
    expect(problemsOf({ ...validEnv(), ...overrides })).not.toBe('');
  });

  it('reads adapters, previous keys and the log level', () => {
    const c = loadConfig({
      ...validEnv(),
      JWT_PREVIOUS_PUBLIC_KEYS: `k0:${seed},`,
      SMS_ADAPTER: 'sslwireless',
      SSLWIRELESS_API_TOKEN: 't',
      SSLWIRELESS_SID: 's',
      PUSH_ADAPTER: 'fcm',
      FCM_CREDENTIALS_FILE: '/creds.json',
      APP_ENV: 'prod',
      LOG_LEVEL: 'DEBUG',
      S3_PUBLIC_ENDPOINT: 'http://public',
    });
    expect(c.jwt.previousKeys.get('k0')?.asymmetricKeyType).toBe('ed25519');
    expect(c.sslWireless).toEqual({ apiToken: 't', sid: 's' });
    expect(c.fcmCredentialsFile).toBe('/creds.json');
    expect(c.logLevel).toBe('debug');
    expect(c.s3.publicEndpoint).toBe('http://public');
  });

  it('logs no secrets', () => {
    const c = loadConfig({ ...validEnv(), S3_SECRET_KEY: 'super-secret' });
    const fields = JSON.stringify(configLogFields(c));
    expect(fields).not.toContain('super-secret');
    expect(fields).toContain('app_env');
  });
});

describe('ConfigModule', () => {
  it('provides the given configuration or reads the environment', async () => {
    const given = loadConfig(validEnv());
    const withGiven = await Test.createTestingModule({
      imports: [ConfigModule.forRoot(given)],
    }).compile();
    expect(withGiven.get<AppConfig>(APP_CONFIG)).toBe(given);

    const saved = process.env;
    process.env = { ...validEnv(), APP_ENV: 'staging' };
    try {
      const fromEnv = await Test.createTestingModule({
        imports: [ConfigModule.forRoot()],
      }).compile();
      expect(fromEnv.get<AppConfig>(APP_CONFIG).appEnv).toBe('staging');
    } finally {
      process.env = saved;
    }
  });
});
