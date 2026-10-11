// The worker process: the outbox relay and the periodic jobs, plus liveness and metrics
// on METRICS_ADDR. `node dist/worker.js healthcheck` is the container health check.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { workerServer } from './app/internal-servers';
import { WorkerModule } from './app/worker.module';
import { loadConfig } from './platform/config/load-config';
import { probe } from './platform/health/probe';
import { closeServer, listen } from './platform/http/listen';
import { createLogger, LOGGER, type Logger, NestLoggerAdapter } from './platform/logging/logger';

async function run(): Promise<void> {
  const config = loadConfig(process.env);
  const app = await NestFactory.createApplicationContext(WorkerModule.forRoot(config), {
    bufferLogs: true,
  });
  const log = app.get<Logger>(LOGGER);
  app.useLogger(new NestLoggerAdapter(log));
  const server = workerServer(app);
  await listen(server, config.metricsAddr);
  log.info('worker started');

  const shutdown = async (): Promise<void> => {
    log.info('worker stopping');
    await closeServer(server, 1000);
    await app.close();
    process.exit(0);
  };
  process.once('SIGTERM', () => void shutdown());
  process.once('SIGINT', () => void shutdown());
}

async function main(): Promise<void> {
  if (process.argv[2] === 'healthcheck') {
    await probe('http://127.0.0.1:9090/healthz', 2000);
    return;
  }
  await run();
}

main().catch((err: unknown) => {
  createLogger('error').error({ err }, 'worker stopped');
  process.exit(1);
});
