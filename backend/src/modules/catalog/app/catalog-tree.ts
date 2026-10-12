import { Inject, Injectable } from '@nestjs/common';
import { LOGGER, type Logger } from '../../../platform/logging/logger';
import { REDIS_KEYS, type RedisKeys } from '../../../platform/redis/redis-client';
import { type Category, publishedOnly } from '../domain/catalog';
import {
  CATALOG_REPOSITORY,
  type CatalogRepository,
  TREE_CACHE,
  type TreeCache,
} from '../port/catalog-repository';

// The version in the key already makes edits visible at once; the TTL only bounds how
// long an unused tree stays in Redis.
const CACHE_TTL_MS = 10 * 60_000;

/** A catalog snapshot with its version. */
export interface Tree {
  readonly version: number;
  readonly categories: Category[];
}

/** Reads the whole catalog tree: published for the apps (cached), everything for admins. */
@Injectable()
export class CatalogTree {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repo: CatalogRepository,
    @Inject(TREE_CACHE) private readonly cache: TreeCache,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
    @Inject(LOGGER) private readonly log: Logger,
  ) {}

  /**
   * What customers and providers browse, from the cache while the version is unchanged
   * (C-03). A cache failure only costs a database read.
   */
  async published(): Promise<Tree> {
    const version = await this.repo.version();
    const key = this.keys.key('cache', 'catalog', `v${String(version)}`);
    const cached = await this.cache.get<Category[]>(key).catch((err: unknown) => {
      this.log.warn({ err }, 'catalog cache read failed');
      return undefined;
    });
    if (cached) {
      return { version, categories: cached };
    }
    const categories = publishedOnly(await this.repo.tree());
    await this.cache.set(key, categories, CACHE_TTL_MS).catch((err: unknown) => {
      this.log.warn({ err }, 'catalog cache write failed');
    });
    return { version, categories };
  }

  /** Everything, published or not (A03). */
  async all(): Promise<Tree> {
    const version = await this.repo.version();
    return { version, categories: await this.repo.tree() };
  }
}
