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
});
