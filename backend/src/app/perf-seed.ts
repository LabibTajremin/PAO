import { randomUUID } from 'node:crypto';
import { type TokenSigner } from '../platform/auth/access-token';
import { type AppConfig } from '../platform/config/app-config';
import { type Point } from '../platform/geo/point';
import { type PerfSeeder } from '../platform/seeding/seeders';

/** What the load-test scripts need to call the API as customers. */
export interface PerfFixture {
  readonly tokens: string[];
  readonly serviceId: string;
  readonly subServiceId: string;
  readonly lat: number;
  readonly lng: number;
}

/** Banani, Dhaka; seeded providers spread around it. */
export const PERF_CENTRE: Point = { lat: 23.7937, lng: 90.4066 };

const CUSTOMER_TOKENS = 50;

/** Where the k-th of n providers stands: a golden-angle spiral about 3 km across. */
export function spiralPoint(k: number, n: number): Point {
  const r = 0.03 * Math.sqrt(k / n);
  const a = k * 2.39996;
  return { lat: PERF_CENTRE.lat + r * Math.sin(a), lng: PERF_CENTRE.lng + r * Math.cos(a) };
}

/**
 * Puts `n` verified electricians online around Dhaka and returns customer tokens for the
 * nearby-search load test (03-testing.md). `signer` issues 2-hour tokens.
 */
export async function seedPerf(
  config: AppConfig,
  seeder: PerfSeeder,
  signer: TokenSigner,
  n: number,
): Promise<PerfFixture> {
  if (config.appEnv === 'prod') {
    throw new Error('perf seed refuses to run in production');
  }
  for (let k = 0; k < n; k++) {
    await seeder.addOnlineProvider(randomUUID(), spiralPoint(k, n));
  }
  const tokens: string[] = [];
  for (let i = 0; i < CUSTOMER_TOKENS; i++) {
    const signed = await signer.sign({
      subject: randomUUID(),
      roles: ['customer'],
      sessionId: randomUUID(),
    });
    tokens.push(signed.token);
  }
  return {
    tokens,
    serviceId: seeder.serviceId,
    subServiceId: seeder.subServiceId,
    lat: PERF_CENTRE.lat,
    lng: PERF_CENTRE.lng,
  };
}
