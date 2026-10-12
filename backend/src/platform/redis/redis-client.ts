import Redis from 'ioredis';

/** Injection token for the shared ioredis client. */
export const REDIS = Symbol('Redis');

/** Injection token for the {@link RedisKeys} of this environment. */
export const REDIS_KEYS = Symbol('RedisKeys');

/** Builds keys under `pao:{env}:` so environments can share one server (02-architecture §4). */
export class RedisKeys {
  private readonly prefix: string;

  constructor(env: string) {
    this.prefix = `pao:${env}:`;
  }

  /** Joins parts with ":" under the prefix, e.g. `key('otp', phone)`. */
  key(...parts: string[]): string {
    return this.prefix + parts.join(':');
  }
}

/** Opens a client for a `redis://` or `rediss://` URL and checks that the server answers. */
export async function connectRedis(url: string): Promise<Redis> {
  if (!/^rediss?:\/\//.test(url)) {
    throw new Error('parse redis url: scheme must be redis:// or rediss://');
  }
  const client = new Redis(url, { lazyConnect: true, maxRetriesPerRequest: 2 });
  // Connection drops are retried by ioredis; the error event only needs a listener.
  client.on('error', () => undefined);
  try {
    await client.connect();
    await client.ping();
  } catch (cause) {
    client.disconnect();
    throw new Error('ping redis', { cause });
  }
  return client;
}
