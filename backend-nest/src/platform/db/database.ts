import { Pool, type PoolClient, type QueryResult, type QueryResultRow } from 'pg';
import { poolConfig } from './pool-config';

/**
 * What repositories run SQL on: the pool or a transaction's client. It satisfies the
 * `Client` interface of sqlc-generated query functions.
 */
export type SqlClient = Pick<PoolClient, 'query'>;

/** A client checked out of the pool; `done` returns it (`broken` discards it). */
export type CheckedOutClient = PoolClient & { done: (broken?: boolean) => void };

/** Injection token for the {@link Database}. */
export const DATABASE = Symbol('Database');

/** The Postgres connection pool with transactions scoped to one module. */
export class Database {
  private closing: Promise<void> | undefined;

  /**
   * `onError` hears connections that fail while idle in the pool; without a listener
   * such an error would crash the process.
   */
  constructor(
    readonly pool: Pool,
    onError: (err: Error) => void = () => undefined,
  ) {
    pool.on('error', onError);
  }

  /**
   * Checks out a client for several statements. A checked-out client that loses its
   * connection reports it as an event, which is only safe with a listener attached.
   */
  async checkout(): Promise<CheckedOutClient> {
    const client = await this.pool.connect();
    const ignore = (): void => undefined;
    client.on('error', ignore);
    return Object.assign(client, {
      done: (broken = false) => {
        client.off('error', ignore);
        client.release(broken);
      },
    });
  }

  /** Runs one parameterised statement on a pooled connection. */
  query<R extends QueryResultRow>(text: string, values?: unknown[]): Promise<QueryResult<R>> {
    return this.pool.query<R>(text, values);
  }

  /**
   * Runs `fn` in a transaction, committing when it resolves and rolling back when it
   * throws. A transaction never spans two modules (PRD §9.3 rule 6): callers hand the
   * client only to their own module's repositories.
   */
  async transaction<T>(fn: (tx: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.begin();
    let broken = false;
    try {
      const result = await runOrRollback(client, fn, () => (broken = true));
      await commit(client);
      return result;
    } finally {
      client.done(broken);
    }
  }

  private async begin(): Promise<CheckedOutClient> {
    let client: CheckedOutClient | undefined;
    try {
      client = await this.checkout();
      await client.query('BEGIN');
      return client;
    } catch (cause) {
      client?.done(true);
      throw new Error('begin transaction', { cause });
    }
  }

  /** Checks that the database answers, for readiness. */
  async ping(): Promise<void> {
    await this.pool.query('SELECT 1');
  }

  /** Closes every connection; later calls wait for the first. */
  close(): Promise<void> {
    this.closing ??= this.pool.end();
    return this.closing;
  }
}

async function runOrRollback<T>(
  client: PoolClient,
  fn: (tx: PoolClient) => Promise<T>,
  markBroken: () => void,
): Promise<T> {
  try {
    return await fn(client);
  } catch (err) {
    // A connection whose rollback failed is in an unknown state; it must not be reused.
    await client.query('ROLLBACK').catch(markBroken);
    throw err;
  }
}

async function commit(client: PoolClient): Promise<void> {
  try {
    await client.query('COMMIT');
  } catch (cause) {
    throw new Error('commit transaction', { cause });
  }
}

/** Opens a pool for `url` and checks that the database answers. */
export async function connectDatabase(
  url: string,
  onError?: (err: Error) => void,
): Promise<Database> {
  const db = new Database(new Pool(poolConfig(url)), onError);
  try {
    await db.ping();
  } catch (cause) {
    await db.close();
    throw new Error('ping database', { cause });
  }
  return db;
}

/**
 * Reports whether `err` is a Postgres unique-constraint violation, optionally on the
 * named constraint.
 */
export function isUniqueViolation(err: unknown, constraint?: string): boolean {
  for (let e: unknown = err; e instanceof Error; e = e.cause) {
    const pg = e as Error & { code?: string; constraint?: string };
    if (pg.code === '23505') {
      return constraint === undefined || constraint === '' || pg.constraint === constraint;
    }
  }
  return false;
}
