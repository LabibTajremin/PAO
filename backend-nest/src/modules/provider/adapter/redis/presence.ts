import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { type ChainableCommander } from 'ioredis';
import { DomainError } from '../../../../platform/errors/domain-error';
import { REDIS, REDIS_KEYS, type RedisKeys } from '../../../../platform/redis/redis-client';
import { type Point } from '../../domain/provider';
import { ProviderReasons } from '../../domain/reasons';
import { type Hit, type Presence } from '../../port/presence';

/** Three missed 30-second heartbeats. */
const HEARTBEAT_TTL_MS = 90_000;

/** Fails when any command of a transaction failed. */
async function run(tx: ChainableCommander): Promise<void> {
  const results = (await tx.exec()) ?? [];
  const failed = results.find(([err]) => err !== null)?.[0];
  if (failed) {
    throw failed;
  }
}

/**
 * Presence in Redis: a GEO set per service and a heartbeat key per provider. Positions
 * live only here and vanish on going offline (PRD §11).
 */
@Injectable()
export class RedisPresence implements Presence {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  private geoKey(service: string): string {
    return this.keys.key('presence', 'svc', service);
  }

  private beatKey(id: string): string {
    return this.keys.key('presence', 'hb', id);
  }

  private onlineKey(): string {
    return this.keys.key('presence', 'online');
  }

  online(id: string, services: readonly string[], at: Point): Promise<void> {
    const tx = this.redis.multi();
    for (const s of services) {
      tx.geoadd(this.geoKey(s), at.lng, at.lat, id);
    }
    tx.set(this.beatKey(id), '1', 'PX', HEARTBEAT_TTL_MS);
    tx.sadd(this.onlineKey(), id);
    return run(tx);
  }

  async beat(id: string, services: readonly string[], at: Point): Promise<void> {
    if ((await this.redis.sismember(this.onlineKey(), id)) !== 1) {
      throw new DomainError(ProviderReasons.Offline);
    }
    await this.online(id, services, at);
  }

  offline(id: string, services: readonly string[]): Promise<void> {
    const tx = this.redis.multi();
    for (const s of services) {
      tx.zrem(this.geoKey(s), id);
    }
    tx.del(this.beatKey(id));
    tx.srem(this.onlineKey(), id);
    return run(tx);
  }

  async isOnline(id: string): Promise<boolean> {
    return (await this.redis.exists(this.beatKey(id))) === 1;
  }

  /** Members whose heartbeat lapsed are skipped even before the reaper removes them. */
  async near(service: string, at: Point, radiusM: number): Promise<Hit[]> {
    const rows = (await this.redis.geosearch(
      this.geoKey(service),
      'FROMLONLAT',
      at.lng,
      at.lat,
      'BYRADIUS',
      radiusM,
      'm',
      'ASC',
      'COUNT',
      200,
      'WITHDIST',
    )) as [string, string][];
    const hits: Hit[] = [];
    for (const [id, dist] of rows) {
      if (await this.isOnline(id)) {
        hits.push({ id, distanceM: Math.trunc(Number(dist)) });
      }
    }
    return hits;
  }

  async lost(): Promise<string[]> {
    const lost: string[] = [];
    for (const id of await this.redis.smembers(this.onlineKey())) {
      if (!(await this.isOnline(id))) {
        lost.push(id);
      }
    }
    return lost;
  }
}
