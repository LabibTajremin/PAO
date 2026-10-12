import { type IncomingMessage, type ServerResponse } from 'node:http';
import { EventEmitter } from 'node:events';
import { Test } from '@nestjs/testing';
import { Metrics, METRICS } from './metrics';
import { MetricsModule } from './metrics.module';

function serve(m: Metrics, url: string, status: number, route?: string): void {
  const req = { method: 'GET', url } as IncomingMessage;
  const res = Object.assign(new EventEmitter(), {
    statusCode: status,
  }) as unknown as ServerResponse;
  let called = false;
  m.middleware(() => route)(req, res, () => {
    called = true;
  });
  expect(called).toBe(true);
  res.emit('finish');
}

describe('Metrics', () => {
  it('records requests under their route template', async () => {
    const m = new Metrics();
    serve(m, '/v1/bookings/123', 418, '/v1/bookings/{id}');
    serve(m, '/x', 404);
    const out = await m.render();
    expect(out.contentType).toContain('text/plain');
    expect(out.body).toContain(
      'pao_http_requests_total{route="/v1/bookings/{id}",method="GET",status="418"} 1',
    );
    expect(out.body).toContain('route="unmatched",method="GET",status="404"');
    expect(out.body).toContain(
      'pao_http_request_duration_seconds_count{route="/v1/bookings/{id}",method="GET"} 1',
    );
    expect(out.body).toContain('process_cpu_user_seconds_total');
  });

  it('labels a request without a method with an empty method', async () => {
    const m = new Metrics();
    const res = Object.assign(new EventEmitter(), { statusCode: 200 }) as unknown as ServerResponse;
    m.middleware(() => undefined)({} as IncomingMessage, res, () => undefined);
    res.emit('finish');
    expect((await m.render()).body).toContain('method="",status="200"');
  });

  it('is provided by MetricsModule', async () => {
    const ref = await Test.createTestingModule({ imports: [MetricsModule] }).compile();
    expect(ref.get(METRICS)).toBeInstanceOf(Metrics);
  });

  it('records job runs, deliveries and the outbox backlog for the worker', async () => {
    const m = new Metrics();
    m.worker.jobFinished('expiry', 'ok', 0.2);
    m.worker.jobFinished('expiry', 'skipped', 0);
    m.worker.eventDelivered('booking', 'booking.BookingRequested');
    m.worker.eventFailed('booking', 'booking.BookingAccepted', true);
    let reads = 0;
    m.worker.trackBacklog(() => {
      reads++;
      return Promise.resolve([{ module: 'booking', pending: 3, dead: 1, oldestSeconds: 42 }]);
    });
    const body = (await m.render()).body;
    expect(body).toContain('pao_job_runs_total{job="expiry",outcome="ok"} 1');
    expect(body).toContain('pao_job_runs_total{job="expiry",outcome="skipped"} 1');
    expect(body).toContain('pao_job_duration_seconds_count{job="expiry"} 1');
    expect(body).toContain(
      'pao_outbox_events_delivered_total{module="booking",event="booking.BookingRequested"} 1',
    );
    expect(body).toContain(
      'pao_outbox_delivery_failures_total{module="booking",event="booking.BookingAccepted",dead="true"} 1',
    );
    expect(body).toContain('pao_outbox_pending_events{module="booking"} 3');
    expect(body).toContain('pao_outbox_oldest_pending_seconds{module="booking"} 42');
    expect(body).toContain('pao_outbox_dead_events{module="booking"} 1');
    expect(reads).toBe(1);
  });

  it('reports no backlog until the worker tracks one', async () => {
    const body = (await new Metrics().render()).body;
    expect(body).toContain('# TYPE pao_outbox_pending_events gauge');
    expect(body).not.toContain('pao_outbox_pending_events{');
  });
});
