import { emptyDatabase } from '../../../test/kit/postgres';
import { FakeClock } from '../clock/fake-clock';
import { connectDatabase, type Database } from '../db/database';
import { createLogger, discardLogger } from '../logging/logger';
import { JobScheduler } from './scheduler';

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe('JobScheduler', () => {
  let db: Database;
  const clock = new FakeClock(new Date('2026-10-09T19:59:59.950Z'));

  beforeAll(async () => {
    db = await connectDatabase(await emptyDatabase());
  });

  afterAll(() => db.close());

  it('lets only one worker run a job at a time', async () => {
    const a = new JobScheduler(db, clock, discardLogger());
    const b = new JobScheduler(db, clock, discardLogger());
    let release = (): void => undefined;
    const runs: string[] = [];
    a.every(60_000, 'sweep', async () => {
      runs.push('a');
      await new Promise<void>((r) => (release = r));
    });
    b.every(60_000, 'sweep', () => {
      runs.push('b');
      return Promise.resolve();
    });
    const first = a.runNow('sweep');
    await sleep(50);
    expect(await b.runNow('sweep')).toBe(false);
    release();
    expect(await first).toBe(true);
    expect(await b.runNow('sweep')).toBe(true);
    expect(runs).toEqual(['a', 'b']);
  });

  it('runs jobs on their timers and logs failures', async () => {
    const logged: string[] = [];
    const s = new JobScheduler(
      db,
      clock,
      createLogger('error', { write: (l: string) => logged.push(l) }),
    );
    let ticks = 0;
    s.every(5, 'tick', () => {
      ticks++;
      return Promise.resolve();
    });
    s.dailyAt(2, 0, 'expiry', () => Promise.reject(new Error('expiry broke')));
    expect(() => {
      s.every(5, 'tick', () => Promise.resolve());
    }).toThrow('scheduled twice');
    s.start();
    await sleep(150);
    await s.stop();
    expect(ticks).toBeGreaterThan(1);
    expect(logged.join('')).toContain('expiry broke');
    await expect(s.runNow('nope')).rejects.toThrow('unknown job nope');
  });

  it('logs a job that cannot reach the database', async () => {
    const lost = await connectDatabase(await emptyDatabase());
    const logged: string[] = [];
    const s = new JobScheduler(
      lost,
      clock,
      createLogger('error', { write: (l: string) => logged.push(l) }),
    );
    s.every(5, 'tick', () => Promise.resolve());
    await lost.close();
    s.start();
    await sleep(50);
    await s.stop();
    expect(logged.join('')).toContain('job could not start');
  });

  it('discards its connection when the lock cannot be released', async () => {
    const s = new JobScheduler(db, clock, discardLogger());
    s.every(60_000, 'suicide', async () => {
      await db.query(
        `SELECT pg_terminate_backend(pid) FROM pg_stat_activity
         WHERE datname = current_database() AND pid <> pg_backend_pid() AND query LIKE '%pg_try_advisory_lock%'`,
      );
    });
    expect(await s.runNow('suicide')).toBe(true);
    await expect(db.ping()).resolves.toBeUndefined();
  });
});
