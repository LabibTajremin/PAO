import { Injectable, Module } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { startTestApi } from '../../test/kit/api';
import { deliver, relayEvents } from '../../test/kit/events';
import { testConfig } from '../../test/kit/api';
import { testRedis } from '../../test/kit/redis';
import { type Clock } from '../platform/clock/clock';
import { DATABASE, type Database } from '../platform/db/database';
import { type DomainEvent } from '../platform/events/domain-event';
import { type EventBus } from '../platform/events/event-bus';
import { closeServer, listen } from '../platform/http/listen';
import { UuidV7Generator } from '../platform/ids/id-generator';
import { type JobScheduler } from '../platform/jobs/scheduler';
import { discardLogger, LOGGER } from '../platform/logging/logger';
import { OutboxWriter } from '../platform/outbox/outbox';
import { REDIS_KEYS } from '../platform/redis/redis-client';
import { PUSH_CAPTURE } from '../platform/testing/test-hooks';
import { WorkerHooksProvider } from '../platform/worker/worker-hooks';
import { apiMetricsServer, workerServer } from './internal-servers';
import { WorkerModule, WorkerRuntime } from './worker.module';

interface Ping extends DomainEvent<'test.Ping'> {
  readonly n: number;
}

const seen: number[] = [];
let jobRuns = 0;

@Injectable()
@WorkerHooksProvider()
class FixtureHooks {
  subscribe(bus: EventBus): void {
    bus.subscribe<Ping>('test.Ping', 'fixture.seen', (env) => {
      seen.push(env.payload.n);
      return Promise.resolve();
    });
  }

  schedule(jobs: JobScheduler): void {
    jobs.every(60_000, 'fixture.job', () => {
      jobRuns++;
      return Promise.resolve();
    });
  }
}

@Injectable()
@WorkerHooksProvider()
class EmptyHooks {}

@Module({
  providers: [FixtureHooks, EmptyHooks, { provide: PUSH_CAPTURE, useValue: { sentTo: () => [] } }],
})
class FixtureModule {}

const until = async (done: () => boolean) => {
  for (let i = 0; i < 200 && !done(); i++) {
    await new Promise((r) => setTimeout(r, 10));
  }
};

async function get(server: ReturnType<typeof workerServer>, path: string) {
  const { port } = await listen(server, '127.0.0.1:0');
  const res = await fetch(`http://127.0.0.1:${port}${path}`);
  const text = await res.text();
  await closeServer(server, 1000);
  return { status: res.status, text };
}

describe('worker', () => {
  it('relays events to module subscribers and runs their jobs', async () => {
    const config = await testConfig();
    const { keys } = await testRedis();
    const ref = await Test.createTestingModule({
      imports: [WorkerModule.forRoot(config), FixtureModule],
    })
      .overrideProvider(LOGGER)
      .useValue(discardLogger())
      .overrideProvider(REDIS_KEYS)
      .useValue(keys)
      .compile();
    const app = await ref.createNestApplication().init();
    const db = app.get<Database>(DATABASE);
    const clock: Clock = { now: () => new Date() };
    const writer = new OutboxWriter('booking', new UuidV7Generator(), clock);
    await db.transaction((tx) => writer.write(tx, 'b1', { name: 'test.Ping', n: 4 } as Ping));
    await until(() => seen.includes(4));
    expect(seen).toContain(4);
    const runtime = app.get(WorkerRuntime);
    expect(await runtime.scheduler.runNow('fixture.job')).toBe(true);
    expect(jobRuns).toBe(1);
    expect(await runtime.scheduler.runNow('outbox.purge_published')).toBe(true);

    expect(await get(workerServer(app), '/healthz')).toEqual({
      status: 200,
      text: '{"status":"ok"}\n',
    });
    const metrics = (await get(workerServer(app), '/metrics')).text;
    expect(metrics).toContain('process_cpu');
    expect(metrics).toContain('pao_outbox_pending_events{module="booking"}');
    expect(metrics).toContain('pao_job_runs_total{job="fixture.job",outcome="ok"} 1');
    expect(metrics).toContain(
      'pao_outbox_events_delivered_total{module="booking",event="test.Ping"}',
    );
    expect(await get(workerServer(app), '/__test/pushes?token=x')).toEqual({
      status: 200,
      text: '{"pushes":[]}\n',
    });
    expect((await get(apiMetricsServer(app), '/metrics')).status).toBe(200);
    await app.close();
  });

  it('serves no test hooks outside APP_ENV=test', async () => {
    const config = { ...(await testConfig()), appEnv: 'dev' as const };
    const ref = await Test.createTestingModule({ imports: [WorkerModule.forRoot(config)] })
      .overrideProvider(LOGGER)
      .useValue(discardLogger())
      .compile();
    const app = await ref.createNestApplication().init();
    expect((await get(workerServer(app), '/__test/pushes')).status).toBe(404);
    await app.close();
  });
});

describe('test kit event helpers', () => {
  it('relay and deliver events to the API app subscribers', async () => {
    const api = await startTestApi({ providers: [FixtureHooks] });
    const db = api.app.get<Database>(DATABASE);
    const writer = new OutboxWriter('booking', new UuidV7Generator(), api.clock);
    await db.transaction((tx) => writer.write(tx, 'b9', { name: 'test.Ping', n: 9 } as Ping));
    await relayEvents(api);
    await deliver(api, { name: 'test.Ping', n: 10 } as Ping);
    expect(seen).toEqual(expect.arrayContaining([9, 10]));
  });
});
