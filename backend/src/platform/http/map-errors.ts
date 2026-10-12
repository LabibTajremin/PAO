import {
  type CallHandler,
  type ExecutionContext,
  type NestInterceptor,
  UseInterceptors,
} from '@nestjs/common';
import { catchError, type Observable, throwError } from 'rxjs';
import { DomainError } from '../errors/domain-error';
import { type ApiError } from './api-error';

/**
 * A module's mapping from `DomainError` reasons to API errors. Each module's
 * `adapter/http` owns one, so error codes exist only at the HTTP edge.
 */
export type ErrorMap = Readonly<Record<string, ApiError>>;

/** Returns the API error for `err` (a DomainError, possibly as a cause), or `err` unchanged. */
export function mapError(map: ErrorMap, err: unknown): unknown {
  for (let e: unknown = err; e instanceof Error; e = e.cause) {
    if (e instanceof DomainError && Object.hasOwn(map, e.reason)) {
      return map[e.reason]?.wrap(err);
    }
  }
  return err;
}

/** Applies an {@link ErrorMap} to whatever a controller throws. */
export class MapErrorsInterceptor implements NestInterceptor {
  constructor(private readonly map: ErrorMap) {}

  intercept(_ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next
      .handle()
      .pipe(catchError((err: unknown) => throwError(() => mapError(this.map, err))));
  }
}

/** Maps a controller's domain errors to API errors: `@MapErrors(bookingErrors)`. */
export const MapErrors = (map: ErrorMap): MethodDecorator & ClassDecorator =>
  UseInterceptors(new MapErrorsInterceptor(map));
