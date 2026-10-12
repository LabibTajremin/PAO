import {
  type CallHandler,
  type ExecutionContext,
  Inject,
  Injectable,
  type NestInterceptor,
} from '@nestjs/common';
import { type Observable } from 'rxjs';
import { VALIDATION_FAILED } from './api-error';
import { type ApiRequest } from './api-request';
import { RequestValidator } from './request-validator';

/**
 * Rejects requests that break the contract with 422 VALIDATION_FAILED before the
 * handler runs, and replaces `req.query` and `req.params` with their typed values.
 *
 * This is an interceptor rather than a pipe: a pipe sees one handler argument at a time
 * and never the matched operation, so it could not check parameters a handler does not
 * read, nor the operations answered by the catch-all. Registered before the idempotency
 * interceptor, an invalid request never claims an idempotency key, as in the Go API.
 */
@Injectable()
export class RequestValidationInterceptor implements NestInterceptor {
  constructor(@Inject(RequestValidator) private readonly validator: RequestValidator) {}

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = ctx.switchToHttp().getRequest<ApiRequest>();
    const op = req.operation;
    if (op) {
      const query = { ...(req.query as Record<string, unknown>) };
      const path = { ...op.pathParams };
      const reason = this.validator.check(op, {
        path,
        query,
        headers: { ...req.headers },
        cookies: { ...(req.cookies as Record<string, unknown> | undefined) },
        contentType: req.headers['content-type'],
        rawBody: req.rawBody,
        bodyError: req.bodyError,
        body: req.body,
      });
      if (reason !== undefined) {
        throw VALIDATION_FAILED.withDetails({ reason });
      }
      Object.defineProperty(req, 'query', { value: query, writable: true });
      Object.assign(req.params, path);
    }
    return next.handle();
  }
}
