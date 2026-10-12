import { type IncomingMessage, type ServerResponse } from 'node:http';
import { collectDefaultMetrics, Counter, Histogram, Registry } from 'prom-client';
import { WorkerMetrics } from './worker-metrics';

/** Returns the route template a request matched (e.g. `/v1/bookings/{id}`), if any. */
export type RouteResolver = (req: IncomingMessage) => string | undefined;

/** Injection token for {@link Metrics}. */
export const METRICS = Symbol('Metrics');

/**
 * Prometheus metrics for requests, errors and latency (PRD §11). The registry is owned
 * by the instance, so nothing is registered globally and tests stay independent.
 */
export class Metrics {
  readonly registry = new Registry();
  /** Job and outbox metrics; only the worker records them. */
  readonly worker = new WorkerMetrics(this.registry);
  private readonly requests: Counter<'route' | 'method' | 'status'>;
  private readonly latency: Histogram<'route' | 'method'>;

  constructor() {
    this.requests = new Counter({
      name: 'pao_http_requests_total',
      help: 'HTTP requests by route, method and status.',
      labelNames: ['route', 'method', 'status'],
      registers: [this.registry],
    });
    this.latency = new Histogram({
      name: 'pao_http_request_duration_seconds',
      help: 'HTTP request latency by route.',
      labelNames: ['route', 'method'],
      buckets: [0.01, 0.025, 0.05, 0.1, 0.2, 0.3, 0.5, 1, 2, 5],
      registers: [this.registry],
    });
    collectDefaultMetrics({ register: this.registry });
  }

  /**
   * Returns Express-style middleware recording each request under its route template,
   * so ids in paths do not explode label cardinality.
   */
  middleware(routeOf: RouteResolver) {
    return (req: IncomingMessage, res: ServerResponse, next: () => void): void => {
      const stop = this.latency.startTimer();
      res.on('finish', () => {
        const route = routeOf(req) ?? 'unmatched';
        const method = req.method ?? '';
        this.requests.inc({ route, method, status: String(res.statusCode) });
        stop({ route, method });
      });
      next();
    };
  }

  /** Renders the registry in the Prometheus text format. */
  async render(): Promise<{ contentType: string; body: string }> {
    return { contentType: this.registry.contentType, body: await this.registry.metrics() };
  }
}
