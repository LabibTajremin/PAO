import { migratedDatabase } from '../../../test/kit/postgres';
import { FakeClock } from '../clock/fake-clock';
import { connectDatabase, type Database } from '../db/database';
import { type DomainEvent } from '../events/domain-event';
import { EventBus } from '../events/event-bus';
import { UuidV7Generator } from '../ids/id-generator';
import { discardLogger } from '../logging/logger';
import { idempotentHandler, OutboxWriter, purgePublishedEvents, readOutboxBacklog } from './outbox';
import { MAX_ATTEMPTS, OutboxRelay } from './outbox-relay';

interface Ping extends DomainEvent<'test.Ping'> {
  readonly n: number;
}

const ping = (n: number): Ping => ({ name: 'test.Ping', n });

describe('outbox', () => {
  let db: Database;
  let clock: FakeClock;
  let writer: OutboxWriter;

  beforeEach(async () => {
    db = await connectDatabase(await migratedDatabase());
    clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
    writer = new OutboxWriter('booking', new UuidV7Generator(), clock);
  });

  afterEach(() => db.close());

  const write = (aggregate: string, n: number) =>
    db.transaction((tx) => writer.write(tx, aggregate, ping(n)));
  const relay = (bus: EventBus, modules = ['booking']) =>
    new OutboxRelay(db, bus, modules, { clock, log: discardLogger() });

  it('delivers exactly once to an idempotent handler, in order per aggregate', async () => {
    const bus = new EventBus();
    const applied: number[] = [];
    bus.subscribe<Ping>(
      'test.Ping',
      'count',
      idempotentHandler<Ping>(db, 'rating', 'count', (_tx, env) => {
        applied.push(env.payload.n);
        return Promise.resolve();
      }),
    );
    let failOnce = true;
    bus.subscribe('test.Ping', 'flaky', () => {
      if (failOnce) {
        failOnce = false;
        return Promise.reject(new Error('transient'));
      }
      return Promise.resolve();
    });
    await write('b1', 1);
    await write('b1', 2);
    await write('b2', 3);
    const r = relay(bus);
    expect(await r.runOnce()).toBe(1);
    expect(await r.runOnce()).toBe(0);
    clock.advance(3000);
    expect(await r.runOnce()).toBe(2);
    expect(applied).toEqual([1, 3, 2]);
  });

  it('dead-letters an event after the last attempt', async () => {
    const bus = new EventBus();
    bus.subscribe('test.Ping', 'broken', () => Promise.reject(new Error('always')));
    await write('b1', 1);
    const r = relay(bus);
    for (let i = 0; i < MAX_ATTEMPTS; i++) {
      await r.runOnce();
      clock.advance(10 * 60_000);
    }
    const { rows } = await db.query<{ dead: boolean; attempts: number; last_error: string }>(
      'SELECT dead, attempts, last_error FROM booking.outbox',
    );
    expect(rows[0]).toEqual({ dead: true, attempts: MAX_ATTEMPTS, last_error: 'broken: always' });
  });

  it('relays on a timer until stopped and logs failed passes', async () => {
    const bus = new EventBus();
    const seen: number[] = [];
    bus.subscribe<Ping>('test.Ping', 'seen', (env) => {
      seen.push(env.payload.n);
      return Promise.resolve();
    });
    await write('b1', 7);
    const r = relay(bus);
    r.start(5);
    for (let i = 0; i < 100 && seen.length === 0; i++) {
      await new Promise((res) => setTimeout(res, 10));
    }
    await r.stop();
    expect(seen).toEqual([7]);
    const broken = relay(bus, ['nosuchmodule']);
    broken.start(5);
    await new Promise((res) => setTimeout(res, 30));
    await broken.stop();
    await relay(bus).stop();
  });

  it('reports encoding, schema and bookkeeping failures', async () => {
    const circular = { name: 'test.Bad' } as DomainEvent & { self?: unknown };
    circular.self = circular;
    await expect(db.transaction((tx) => writer.write(tx, 'a', circular))).rejects.toThrow(
      'encode test.Bad',
    );
    const missing = new OutboxWriter('nosuchmodule', new UuidV7Generator(), clock);
    await expect(db.transaction((tx) => missing.write(tx, 'a', ping(1)))).rejects.toThrow(
      'write test.Ping to nosuchmodule outbox',
    );
    await expect(relay(new EventBus(), ['nosuchmodule']).runOnce()).rejects.toThrow(
      'relay nosuchmodule',
    );
    const handler = idempotentHandler(db, 'nosuchmodule', 'h', () => Promise.resolve());
    const env = {
      id: '0199c4f0-0000-7000-8000-000000000001',
      module: 'x',
      name: 'test.Ping',
      aggregateId: 'a',
      payload: ping(1),
      occurredAt: new Date(),
    };
    await expect(handler(env)).rejects.toThrow('mark');
    await write('b1', 1);
    const bus = new EventBus();
    bus.subscribe('test.Ping', 'kills-the-relay', async () => {
      await db.query(
        `SELECT pg_terminate_backend(pid) FROM pg_stat_activity
         WHERE datname = current_database() AND state = 'idle in transaction'`,
      );
    });
    await expect(relay(bus).runOnce()).rejects.toThrow('relay booking');
  });

  it('purges events delivered before the cutoff', async () => {
    await write('b1', 1);
    await write('b2', 2);
    await db.query("UPDATE booking.outbox SET published_at = $1 WHERE aggregate_id = 'b1'", [
      clock.now(),
    ]);
    await purgePublishedEvents(db, ['booking'], new Date(clock.now().getTime() + 1000));
    const { rows } = await db.query('SELECT aggregate_id FROM booking.outbox');
    expect(rows).toEqual([{ aggregate_id: 'b2' }]);
    await expect(purgePublishedEvents(db, ['nosuchmodule'], clock.now())).rejects.toThrow(
      'purge "nosuchmodule"."outbox"',
    );
  });

  it('tells its observer about deliveries, failures and dead letters', async () => {
    const seen: string[] = [];
    const observer = {
      eventDelivered: (m: string, e: string) => seen.push(`ok ${m} ${e}`),
      eventFailed: (m: string, e: string, dead: boolean) => seen.push(`fail ${m} ${e} ${dead}`),
    };
    const bus = new EventBus();
    let fail = true;
    bus.subscribe('test.Ping', 'flaky', () =>
      fail ? Promise.reject(new Error('down')) : Promise.resolve(),
    );
    await write('b1', 1);
    await db.query('UPDATE booking.outbox SET attempts = $1', [MAX_ATTEMPTS - 2]);
    const r = new OutboxRelay(db, bus, ['booking'], { clock, log: discardLogger(), observer });
    await r.runOnce();
    clock.advance(10 * 60_000);
    await write('b2', 2);
    fail = false;
    await r.runOnce();
    expect(seen).toEqual([
      'fail booking test.Ping false',
      'ok booking test.Ping',
      'ok booking test.Ping',
    ]);
    await db.query('UPDATE booking.outbox SET published_at = NULL, attempts = $1', [
      MAX_ATTEMPTS - 1,
    ]);
    fail = true;
    seen.length = 0;
    await r.runOnce();
    expect(seen).toEqual(['fail booking test.Ping true', 'fail booking test.Ping true']);
  });

  it('reads the backlog of undelivered and dead events', async () => {
    expect(await readOutboxBacklog(db, ['booking'], clock.now())).toEqual([
      { module: 'booking', pending: 0, dead: 0, oldestSeconds: 0 },
    ]);
    await write('b1', 1);
    clock.advance(5000);
    await write('b2', 2);
    await write('b3', 3);
    await db.query("UPDATE booking.outbox SET dead = true WHERE aggregate_id = 'b3'");
    clock.advance(1000);
    expect(await readOutboxBacklog(db, ['booking'], clock.now())).toEqual([
      { module: 'booking', pending: 2, dead: 1, oldestSeconds: 6 },
    ]);
    await expect(readOutboxBacklog(db, ['nosuchmodule'], clock.now())).rejects.toThrow(
      'read backlog of "nosuchmodule"."outbox"',
    );
  });
});
