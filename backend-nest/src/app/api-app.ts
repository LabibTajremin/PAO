import { type INestApplication, type NestApplicationOptions } from '@nestjs/common';
import { type NextFunction, type Request, type Response } from 'express';
import { APP_CONFIG, type AppConfig } from '../platform/config/app-config';
import { LOGGER, type Logger, NestLoggerAdapter } from '../platform/logging/logger';
import { testHooks } from '../platform/testing/test-hooks';
import { testHookSeams } from './platform';

/**
 * Options for creating the API app. The HTTP edge reads bodies itself, so Nest's body
 * parser is off; it reports bad bodies only after authentication, as the Go API did.
 */
export const API_APP_OPTIONS: NestApplicationOptions = { bodyParser: false, bufferLogs: true };

/**
 * Finishes the API app before it listens: Nest logs go to the structured logger and,
 * with APP_ENV=test, the `/__test/` hooks are mounted in front of every route.
 */
export function configureApiApp(app: INestApplication): void {
  const log = app.get<Logger>(LOGGER);
  app.useLogger(new NestLoggerAdapter(log));
  if (app.get<AppConfig>(APP_CONFIG).appEnv !== 'test') {
    return;
  }
  const hooks = testHooks(testHookSeams(app));
  app.use((req: Request, res: Response, next: NextFunction) => {
    hooks(req, res).then((handled) => {
      if (!handled) {
        next();
      }
    }, next);
  });
}
