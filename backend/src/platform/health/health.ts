import { Controller, Get, HttpCode, Inject, Res } from '@nestjs/common';
import { type Response } from 'express';
import { Public } from '../http/permissions';
import { type NonSpecRoute } from '../http/spec-match.middleware';

/** Checks that one dependency (database, Redis, storage) answers. */
export type HealthCheck = () => Promise<unknown>;

/** Injection token for the named {@link HealthCheck}s readiness runs. */
export const HEALTH_CHECKS = Symbol('HealthChecks');

/** The health routes, served outside the contract. */
export const HEALTH_ROUTES: readonly NonSpecRoute[] = [
  { method: 'GET', path: '/healthz' },
  { method: 'GET', path: '/readyz' },
];

/** Readiness: `{status: ok}`, or 503 naming every dependency that did not answer. */
export async function readiness(
  checks: Readonly<Record<string, HealthCheck>>,
): Promise<{ status: number; body: Record<string, unknown> }> {
  const failed: Record<string, string> = {};
  await Promise.all(
    Object.entries(checks).map(async ([name, check]) => {
      await check().catch(() => (failed[name] = 'unavailable'));
    }),
  );
  if (Object.keys(failed).length > 0) {
    return { status: 503, body: { checks: failed, status: 'unavailable' } };
  }
  return { status: 200, body: { status: 'ok' } };
}

/** Liveness and readiness for Docker and load balancers. */
@Controller()
@Public()
export class HealthController {
  constructor(@Inject(HEALTH_CHECKS) private readonly checks: Record<string, HealthCheck>) {}

  /** 200 while the process can serve HTTP at all. */
  @Get('healthz')
  @HttpCode(200)
  liveness(): { status: string } {
    return { status: 'ok' };
  }

  /** 200 only when every dependency answers, so traffic is withheld from a broken instance. */
  @Get('readyz')
  async readiness(@Res({ passthrough: true }) res: Response): Promise<Record<string, unknown>> {
    const result = await readiness(this.checks);
    res.status(result.status);
    return result.body;
  }
}
