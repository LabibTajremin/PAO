import { type Server } from 'node:http';
import { type INestApplicationContext } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../platform/config/app-config';
import {
  createInternalServer,
  type InternalHandler,
  livenessHandler,
  metricsHandler,
} from '../platform/http/internal-server';
import { type Metrics, METRICS } from '../platform/metrics/metrics';
import { testHooks } from '../platform/testing/test-hooks';
import { testHookSeams } from './platform';

/** The API's internal server on METRICS_ADDR: Prometheus metrics only. */
export function apiMetricsServer(app: INestApplicationContext): Server {
  const metrics = app.get<Metrics>(METRICS);
  return createInternalServer([metricsHandler(() => metrics.render())]);
}

/**
 * The worker's only HTTP server, on METRICS_ADDR: liveness for the container health
 * check, metrics and, with APP_ENV=test, the hooks that read captured pushes (the worker
 * sends them).
 */
export function workerServer(app: INestApplicationContext): Server {
  const metrics = app.get<Metrics>(METRICS);
  const handlers: InternalHandler[] = [livenessHandler, metricsHandler(() => metrics.render())];
  if (app.get<AppConfig>(APP_CONFIG).appEnv === 'test') {
    handlers.push(testHooks(testHookSeams(app)));
  }
  return createInternalServer(handlers);
}
