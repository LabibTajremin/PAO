import { type CanActivate, type ExecutionContext, Inject, Injectable } from '@nestjs/common';
import { TokenExpiredError, TokenVerifier } from '../auth/access-token';
import { setRequestUserId } from '../logging/request-context';
import { RbacChecker } from '../rbac/rbac';
import { Denylist } from '../redis/denylist';
import { RateLimiter } from '../redis/rate-limiter';
import { REDIS_KEYS, type RedisKeys } from '../redis/redis-client';
import { FORBIDDEN, rateLimited, TOKEN_EXPIRED, UNAUTHENTICATED } from './api-error';
import { type ApiRequest } from './api-request';
import { AUTHENTICATED, PUBLIC, requiredPermission } from './permissions';
import { type Principal } from './principal';

const request = (ctx: ExecutionContext): ApiRequest => ctx.switchToHttp().getRequest<ApiRequest>();

/** Requires a valid, unrevoked bearer token on every route that is not public. */
@Injectable()
export class AuthenticationGuard implements CanActivate {
  constructor(
    @Inject(TokenVerifier) private readonly verifier: TokenVerifier,
    @Inject(Denylist) private readonly denylist: Denylist,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    if (requiredPermission(ctx) === PUBLIC) {
      return true;
    }
    const req = request(ctx);
    req.principal = await this.principal(req.headers.authorization);
    setRequestUserId(req.principal.accountId);
    return true;
  }

  private async principal(authorization: string | undefined): Promise<Principal> {
    const token = authorization?.startsWith('Bearer ') ? authorization.slice(7) : '';
    if (token === '') {
      throw UNAUTHENTICATED;
    }
    let claims;
    try {
      claims = await this.verifier.verify(token);
    } catch (err) {
      throw err instanceof TokenExpiredError ? TOKEN_EXPIRED : UNAUTHENTICATED;
    }
    if (await this.denylist.isDenied(claims.tokenId)) {
      throw UNAUTHENTICATED;
    }
    return {
      accountId: claims.subject,
      roles: claims.roles,
      tokenId: claims.tokenId,
      sessionId: claims.sessionId,
      expiresAt: claims.expiresAt,
    };
  }
}

/**
 * Enforces the route's permission against the caller's roles (02-architecture §6). A
 * route without a permission decorator is denied.
 */
@Injectable()
export class AuthorizationGuard implements CanActivate {
  constructor(@Inject(RbacChecker) private readonly rbac: RbacChecker) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const permission = requiredPermission(ctx);
    if (permission === PUBLIC) {
      return true;
    }
    if (permission === undefined) {
      throw FORBIDDEN;
    }
    const principal = request(ctx).principal;
    if (!principal) {
      throw UNAUTHENTICATED;
    }
    if (permission !== AUTHENTICATED && !(await this.rbac.has(principal.roles, permission))) {
      throw FORBIDDEN.withDetails({ permission });
    }
    return true;
  }
}

/** Per-operation API limits: per signed-in user, or per IP for anonymous calls. */
export interface RateLimits {
  readonly perUser: number;
  readonly perIp: number;
  readonly windowMs: number;
}

/** Injection token for the {@link RateLimits}. */
export const RATE_LIMITS = Symbol('RateLimits');

/** The production API limits: 120 calls a minute per user, 60 per IP, per operation. */
export const API_RATE_LIMITS: RateLimits = { perUser: 120, perIp: 60, windowMs: 60_000 };

/** Applies the API rate limit to every spec operation (`rl:api:{subject}:{operation}`). */
@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    @Inject(RateLimiter) private readonly limiter: RateLimiter,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
    @Inject(RATE_LIMITS) private readonly limits: RateLimits,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const req = request(ctx);
    if (!req.operation) {
      return true;
    }
    const [subject, limit] = req.principal
      ? [`user:${req.principal.accountId}`, this.limits.perUser]
      : [`ip:${req.clientIp ?? ''}`, this.limits.perIp];
    const key = this.keys.key('rl', 'api', subject, req.operation.id);
    const decision = await this.limiter.allow(key, limit, this.limits.windowMs);
    if (!decision.allowed) {
      throw rateLimited('RATE_LIMITED', decision.retryAfterMs);
    }
    return true;
  }
}
