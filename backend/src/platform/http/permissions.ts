import { type ExecutionContext, SetMetadata } from '@nestjs/common';
import { type ApiRequest } from './api-request';

/** No token needed (x-permission `public`). */
export const PUBLIC = 'public';
/** Any signed-in account (x-permission `authenticated`). */
export const AUTHENTICATED = 'authenticated';

const PERMISSION_KEY = 'pao:permission';
/** Marks the catch-all route whose permission is the matched operation's x-permission. */
export const FROM_SPEC = Symbol('permission from spec');

/**
 * Requires the caller's roles to grant `permission` (e.g. `booking:create`). The value
 * must equal the operation's `x-permission`; {@link checkRoutesAgainstSpec} verifies it.
 * `:own` permissions still need an ownership check in the use case.
 */
export const RequirePermission = (permission: string): MethodDecorator & ClassDecorator =>
  SetMetadata(PERMISSION_KEY, permission);

/** Lets anyone call the route, without a token. */
export const Public = (): MethodDecorator & ClassDecorator => SetMetadata(PERMISSION_KEY, PUBLIC);

/** Lets any signed-in account call the route. */
export const Authenticated = (): MethodDecorator & ClassDecorator =>
  SetMetadata(PERMISSION_KEY, AUTHENTICATED);

/**
 * Takes the permission from the matched operation's `x-permission`; only for the
 * catch-all that answers operations no module serves yet.
 */
export const PermissionFromSpec = (): MethodDecorator & ClassDecorator =>
  SetMetadata(PERMISSION_KEY, FROM_SPEC);

/** Reads the permission a route declares, if any. */
export function declaredPermission(
  handler: object,
  controller: object,
): string | symbol | undefined {
  return (Reflect.getMetadata(PERMISSION_KEY, handler) ??
    Reflect.getMetadata(PERMISSION_KEY, controller)) as string | symbol | undefined;
}

/**
 * The permission a request needs. Undefined means the route declares none, and the
 * request is denied (deny by default, 02-architecture §7).
 */
export function requiredPermission(ctx: ExecutionContext): string | undefined {
  const declared = declaredPermission(ctx.getHandler(), ctx.getClass());
  if (declared === FROM_SPEC) {
    return ctx.switchToHttp().getRequest<ApiRequest>().operation?.permission;
  }
  return typeof declared === 'string' ? declared : undefined;
}
