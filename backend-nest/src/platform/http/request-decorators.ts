import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import { UNAUTHENTICATED } from './api-error';
import { type ApiRequest } from './api-request';
import { type Principal } from './principal';

/** Returns the authenticated caller of a request, or throws 401 if there is none. */
export function principalOf(req: ApiRequest): Principal {
  if (!req.principal) {
    throw UNAUTHENTICATED;
  }
  return req.principal;
}

/** Injects the authenticated {@link Principal} into a controller method. */
export const CurrentPrincipal = createParamDecorator((_data: unknown, ctx: ExecutionContext) =>
  principalOf(ctx.switchToHttp().getRequest<ApiRequest>()),
);

/** Injects the caller's IP address, e.g. for per-IP OTP limits. */
export const ClientIp = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext) => ctx.switchToHttp().getRequest<ApiRequest>().clientIp,
);
