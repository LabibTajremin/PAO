import { Inject, Injectable, type NestMiddleware } from '@nestjs/common';
import { type NextFunction, type Response } from 'express';
import { LOGGER, type Logger } from '../logging/logger';
import { METHOD_NOT_ALLOWED, NOT_FOUND } from './api-error';
import { type ApiRequest } from './api-request';
import { writeError } from './error-response';
import { SpecRoutes } from './spec-routes';

/** A route served outside the contract, such as the health checks. */
export interface NonSpecRoute {
  readonly method: string;
  readonly path: string;
}

/** Injection token for the {@link NonSpecRoute}s the API also serves. */
export const NON_SPEC_ROUTES = Symbol('NonSpecRoutes');

/**
 * Matches each request to an operation of the contract and stores it on the request,
 * so authentication and authorisation run before the body is looked at. Unknown paths
 * get 404 and known paths with the wrong method 405, before any controller runs.
 */
@Injectable()
export class SpecMatchMiddleware implements NestMiddleware {
  constructor(
    @Inject(SpecRoutes) private readonly routes: SpecRoutes,
    @Inject(NON_SPEC_ROUTES) private readonly nonSpec: readonly NonSpecRoute[],
    @Inject(LOGGER) private readonly log: Logger,
  ) {}

  use(req: ApiRequest, res: Response, next: NextFunction): void {
    const path = new URL(req.originalUrl, 'http://api').pathname;
    const own = this.nonSpec.filter((r) => r.path === path);
    if (own.length > 0) {
      if (!own.some((r) => r.method === req.method)) {
        writeError(res, METHOD_NOT_ALLOWED, this.log);
        return;
      }
      req.routeTemplate = path;
      next();
      return;
    }
    const match = this.routes.match(req.method, path);
    if (match === 'not_found' || match === 'method_not_allowed') {
      writeError(res, match === 'not_found' ? NOT_FOUND : METHOD_NOT_ALLOWED, this.log);
      return;
    }
    req.operation = match;
    req.routeTemplate = match.pathTemplate;
    next();
  }
}
