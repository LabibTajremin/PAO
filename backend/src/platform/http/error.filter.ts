import { type ArgumentsHost, Catch, type ExceptionFilter, Inject } from '@nestjs/common';
import { type Response } from 'express';
import { LOGGER, type Logger } from '../logging/logger';
import { type ApiRequest } from './api-request';
import { writeError } from './error-response';

/** The one place errors become HTTP answers: the PRD §9.6 envelope, Retry-After on 429. */
@Catch()
export class ErrorFilter implements ExceptionFilter {
  constructor(@Inject(LOGGER) private readonly log: Logger) {}

  catch(err: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const req = http.getRequest<ApiRequest>();
    writeError(http.getResponse<Response>(), err, this.log, req.path);
  }
}
