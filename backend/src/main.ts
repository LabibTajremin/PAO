// The API process: `node dist/main.js` serves the contract on HTTP_ADDR and metrics on
// METRICS_ADDR; `node dist/main.js healthcheck` is the container health check.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { API_APP_OPTIONS, configureApiApp } from './app/api-app';
import { AppModule } from './app/app.module';
import { apiMetricsServer } from './app/internal-servers';
import { configLogFields } from './platform/config/app-config';
import { loadConfig } from './platform/config/load-config';
import { probe } from './platform/health/probe';
import { closeServer, listen, parseListenAddress } from './platform/http/listen';
import { createLogger, LOGGER, type Logger } from './platform/logging/logger';

const DRAIN_MS = 10_000;

async function serve(): Promise<void> {
  const config = loadConfig(process.env);
  const app = await NestFactory.create(AppModule.forRoot(config), API_APP_OPTIONS);
  await configureApiApp(app);
  const log = app.get<Logger>(LOGGER);
  const metrics = apiMetricsServer(app);
  await listen(metrics, config.metricsAddr);
  const { host, port } = parseListenAddress(config.httpAddr);
  await app.listen(port, host ?? '0.0.0.0');
  log.info({ config: configLogFields(config) }, 'api starting');

  const shutdown = async (): Promise<void> => {
    log.info('api stopping');
    const timeout = new Promise((resolve) => setTimeout(resolve, DRAIN_MS));
    await Promise.race([Promise.all([app.close(), closeServer(metrics, 1000)]), timeout]);
    process.exit(0);
  };
  process.once('SIGTERM', () => void shutdown());
  process.once('SIGINT', () => void shutdown());
}

async function main(): Promise<void> {
  if (process.argv[2] === 'healthcheck') {
    await probe('http://127.0.0.1:8080/healthz', 2000);
    return;
  }
  await serve();
}

main().catch((err: unknown) => {
  createLogger('error').error({ err }, 'api stopped');
  process.exit(1);
});
