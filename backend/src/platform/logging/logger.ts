import { type LoggerService } from '@nestjs/common';
import pino, { type DestinationStream, type Logger as PinoLogger } from 'pino';
import { type LogLevel } from '../config/app-config';
import { currentRequestContext } from './request-context';

/** The structured JSON logger every component writes to (PRD §11 observability). */
export type Logger = PinoLogger;

/** Injection token for the {@link Logger}. */
export const LOGGER = Symbol('Logger');

function contextFields(): Record<string, string> {
  const ctx = currentRequestContext();
  const fields: Record<string, string> = {};
  if (ctx?.requestId) {
    fields.request_id = ctx.requestId;
  }
  if (ctx?.userId) {
    fields.user_id = ctx.userId;
  }
  return fields;
}

/**
 * Returns a JSON logger shaped like the Go backend's slog output (`time`, `level`,
 * `msg`) that adds request_id and user_id of the request being served.
 */
export function createLogger(level: LogLevel, destination?: DestinationStream): Logger {
  const options = {
    level,
    base: undefined,
    messageKey: 'msg',
    timestamp: pino.stdTimeFunctions.isoTime,
    formatters: { level: (label: string) => ({ level: label.toUpperCase() }) },
    mixin: contextFields,
  };
  return destination ? pino(options, destination) : pino(options);
}

/** A logger that drops everything; for tests. */
export function discardLogger(): Logger {
  return pino({ enabled: false });
}

/** Routes Nest's own framework logs into the structured logger. */
export class NestLoggerAdapter implements LoggerService {
  constructor(private readonly logger: Logger) {}

  log(message: unknown, context?: string): void {
    this.logger.info({ context }, String(message));
  }

  error(message: unknown, trace?: string, context?: string): void {
    this.logger.error({ context, trace }, String(message));
  }

  warn(message: unknown, context?: string): void {
    this.logger.warn({ context }, String(message));
  }

  debug(message: unknown, context?: string): void {
    this.logger.debug({ context }, String(message));
  }

  verbose(message: unknown, context?: string): void {
    this.logger.trace({ context }, String(message));
  }
}
