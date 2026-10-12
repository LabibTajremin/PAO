import { Test } from '@nestjs/testing';
import { emptyDatabase } from '../../../test/kit/postgres';
import { type AppConfig } from '../config/app-config';
import { ConfigModule } from '../config/config.module';
import { connectDatabase, DATABASE, Database } from './database';
import { DatabaseModule } from './database.module';

const UNREACHABLE = 'postgres://pao:pao@127.0.0.1:1/pao?connect_timeout=1';

describe('Database', () => {
  let db: Database;

  beforeAll(async () => {
    db = await connectDatabase(await emptyDatabase());
    await db.query('CREATE TABLE t (v int)');
  });

  afterAll(() => db.close());

  it('commits and rolls back', async () => {
    const insert = (tx: { query: (s: string) => Promise<unknown> }) =>
      tx.query('INSERT INTO t VALUES (1)');
    await expect(db.transaction(async (tx) => insert(tx).then(() => 'ok'))).resolves.toBe('ok');
    const boom = new Error('boom');
    await expect(
      db.transaction(async (tx) => {
        await insert(tx);
        throw boom;
      }),
    ).rejects.toBe(boom);
    await expect(
      db.transaction((tx) =>
        tx.query(
          'SET CONSTRAINTS ALL DEFERRED; CREATE TABLE u (v int UNIQUE DEFERRABLE INITIALLY DEFERRED); INSERT INTO u VALUES (1), (1)',
        ),
      ),
    ).rejects.toThrow('commit transaction');
    const { rows } = await db.query<{ n: string }>('SELECT count(*) AS n FROM t');
    expect(rows[0]?.n).toBe('1');
  });

  it('discards a connection whose rollback failed', async () => {
    await expect(
      db.transaction((tx) => tx.query('SELECT pg_terminate_backend(pg_backend_pid())')),
    ).rejects.toThrow();
    await expect(db.ping()).resolves.toBeUndefined();
  });

  it('survives connection errors reported as events', async () => {
    db.pool.emit('error', new Error('idle client lost'));
    const client = await db.checkout();
    client.emit('error', new Error('checked-out client lost'));
    client.done();
    const heard: Error[] = [];
    const other = await connectDatabase(await emptyDatabase(), (err) => heard.push(err));
    other.pool.emit('error', new Error('idle'));
    expect(heard).toHaveLength(1);
    await other.close();
  });

  it('closes once even when asked twice', async () => {
    const other = await connectDatabase(await emptyDatabase());
    await Promise.all([other.close(), other.close()]);
    await expect(other.ping()).rejects.toThrow();
  });
});

describe('connectDatabase', () => {
  it('fails when the database is unreachable or the URL is invalid', async () => {
    await expect(connectDatabase(UNREACHABLE)).rejects.toThrow('ping database');
    await expect(connectDatabase('postgres://%zz')).rejects.toThrow();
  });

  it('reports a failed begin', async () => {
    const db = await connectDatabase(await emptyDatabase());
    await db.query('SELECT 1');
    const broken = Object.create(db) as Database;
    Object.defineProperty(broken, 'pool', {
      value: { connect: () => Promise.reject(new Error('no connection')) },
    });
    await expect(broken.transaction(() => Promise.resolve(1))).rejects.toThrow('begin transaction');
    const failingBegin = Object.create(db) as Database;
    let released = false;
    Object.defineProperty(failingBegin, 'pool', {
      value: {
        connect: () =>
          Promise.resolve({
            query: () => Promise.reject(new Error('begin refused')),
            release: () => (released = true),
            on: () => undefined,
            off: () => undefined,
          }),
      },
    });
    await expect(failingBegin.transaction(() => Promise.resolve(1))).rejects.toThrow(
      'begin transaction',
    );
    expect(released).toBe(true);
    await db.close();
  });
});

describe('DatabaseModule', () => {
  it('connects at start-up and closes on shutdown', async () => {
    const url = await emptyDatabase();
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ databaseUrl: url } as AppConfig), DatabaseModule],
    }).compile();
    const app = ref.createNestApplication();
    await app.init();
    const db = app.get<Database>(DATABASE);
    expect(db).toBeInstanceOf(Database);
    await expect(db.ping()).resolves.toBeUndefined();
    await app.close();
    await expect(db.ping()).rejects.toThrow();
  });
});
