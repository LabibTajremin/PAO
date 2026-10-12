import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { DATABASE, type Database } from '../db/database';
import { REDIS, REDIS_KEYS, type RedisKeys } from '../redis/redis-client';

/** What one role, or a set of roles, allows. */
export interface Grants {
  readonly permissions: readonly string[];
  readonly screens: readonly string[];
}

/** Loads a role's grants from the system of record. */
export interface RbacSource {
  loadGrants(role: string): Promise<Grants>;
}

/** Injection token for the {@link RbacSource}. */
export const RBAC_SOURCE = Symbol('RbacSource');

/** Reads grants from the identity schema with the same queries as the identity module. */
@Injectable()
export class PostgresRbacSource implements RbacSource {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  async loadGrants(role: string): Promise<Grants> {
    const perms = await this.db.query<{ permission: string }>(
      'SELECT permission FROM identity.role_permissions WHERE role = $1 ORDER BY permission',
      [role],
    );
    const screens = await this.db.query<{ screen_id: string }>(
      'SELECT screen_id FROM identity.role_screens WHERE role = $1 ORDER BY screen_id',
      [role],
    );
    return {
      permissions: perms.rows.map((r) => r.permission),
      screens: screens.rows.map((r) => r.screen_id),
    };
  }
}

// Distinguishes "cached as empty" from "not cached".
const EMPTY_MARKER = '~';
const CACHE_TTL_SECONDS = 3600;

const sortedUnique = (values: string[]): string[] => [...new Set(values)].sort();

/**
 * Answers "may these roles do this?" and "which screens may they see?" from Redis sets
 * keyed by the RBAC version (`rbac:role:{role}:v{n}`, `rbac:screens:{role}:v{n}`),
 * falling back to the identity tables (02-architecture §6).
 */
@Injectable()
export class RbacChecker {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
    @Inject(RBAC_SOURCE) private readonly source: RbacSource,
  ) {}

  /** The current RBAC version; 0 before the first change. */
  async version(): Promise<number> {
    const raw = await this.redis.get(this.keys.key('rbac', 'version'));
    if (raw === null) {
      return 0;
    }
    if (!/^-?\d+$/.test(raw)) {
      throw new Error(`read rbac version: not a number: ${raw}`);
    }
    return Number(raw);
  }

  /** Invalidates every cached role after a role or permission change. */
  bumpVersion(): Promise<number> {
    return this.redis.incr(this.keys.key('rbac', 'version'));
  }

  /** Returns the union of the roles' grants, sorted. */
  async grants(roles: readonly string[]): Promise<Grants> {
    const version = await this.version();
    const permissions: string[] = [];
    const screens: string[] = [];
    for (const role of roles) {
      const g = await this.roleGrants(role, version);
      permissions.push(...g.permissions);
      screens.push(...g.screens);
    }
    return { permissions: sortedUnique(permissions), screens: sortedUnique(screens) };
  }

  /** Reports whether any of the roles grants `permission`. */
  async has(roles: readonly string[], permission: string): Promise<boolean> {
    return (await this.grants(roles)).permissions.includes(permission);
  }

  private async roleGrants(role: string, version: number): Promise<Grants> {
    const permKey = this.keys.key('rbac', 'role', role, `v${version}`);
    const screenKey = this.keys.key('rbac', 'screens', role, `v${version}`);
    const cached = await this.redis.smembers(permKey);
    if (cached.length > 0) {
      const screens = await this.redis.smembers(screenKey);
      return { permissions: withoutMarker(cached), screens: withoutMarker(screens) };
    }
    let g: Grants;
    try {
      g = await this.source.loadGrants(role);
    } catch (cause) {
      throw new Error(`load grants for ${role}`, { cause });
    }
    await this.cache(permKey, g.permissions);
    await this.cache(screenKey, g.screens);
    return g;
  }

  // Best effort: a failed write only costs another database read.
  private async cache(key: string, members: readonly string[]): Promise<void> {
    await this.redis
      .multi()
      .sadd(key, EMPTY_MARKER, ...members)
      .expire(key, CACHE_TTL_SECONDS)
      .exec()
      .catch(() => null);
  }
}

function withoutMarker(members: string[]): string[] {
  return members.filter((m) => m !== EMPTY_MARKER);
}
