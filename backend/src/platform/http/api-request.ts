import { type Request } from 'express';
import { type Principal } from './principal';
import { type MatchedOperation } from './spec-routes';

/** What the HTTP edge learns about a request on its way to the controller. */
export interface ApiRequestState {
  /** The caller's address, after trusting our load balancer's X-Forwarded-For. */
  clientIp?: string;
  /** The body as received, at most 1 MB; idempotency fingerprints it. */
  rawBody?: Buffer;
  /** Why the body could not be read or parsed; reported by request validation. */
  bodyError?: string;
  /** The route template the request matched, for metrics (`/v1/bookings/{id}`). */
  routeTemplate?: string;
  /** The OpenAPI operation the request matched, if it is a spec route. */
  operation?: MatchedOperation;
  /** The authenticated caller. */
  principal?: Principal;
}

/** An Express request carrying the {@link ApiRequestState}. */
export type ApiRequest = Request & ApiRequestState;
