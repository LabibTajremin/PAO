import { timingSafeEqual } from 'node:crypto';

/** Access tokens live 15 minutes (docs/build/02-architecture.md §5). */
export const ACCESS_TTL_MS = 15 * 60_000;
/** A refresh family lives 30 days after its last rotation. */
export const REFRESH_TTL_MS = 30 * 24 * 60 * 60_000;

/**
 * One signed-in device: a chain of refresh tokens where only the newest is valid.
 * Presenting an older one means the chain leaked, so the family is revoked.
 */
export interface Family {
  readonly id: string;
  readonly accountId: string;
  readonly app: string;
  readonly currentHash: string;
  readonly accessTokenId: string;
  readonly accessExpiresAt: Date;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Joins the family id and the secret so a refresh can find its family. */
export function formatRefreshToken(familyId: string, secret: string): string {
  return `${familyId}.${secret}`;
}

/** Splits a refresh token into family id and secret, or undefined when malformed. */
export function parseRefreshToken(token: string): { familyId: string; secret: string } | undefined {
  const dot = token.indexOf('.');
  const familyId = token.slice(0, dot);
  const secret = token.slice(dot + 1);
  return dot < 0 || !UUID.test(familyId) || secret === '' ? undefined : { familyId, secret };
}

/** Compares a presented token hash with the family's current one in constant time. */
export function familyMatches(f: Family, hash: string): boolean {
  const current = Buffer.from(f.currentHash);
  const presented = Buffer.from(hash);
  return current.length === presented.length && timingSafeEqual(current, presented);
}

/** The only partner screens a provider sees before Level 1 (PRD §8.5). */
export const PROVIDER_GATE_SCREENS: readonly string[] = Array.from(
  { length: 14 },
  (_, i) => `M${String(i + 1).padStart(2, '0')}`,
);
