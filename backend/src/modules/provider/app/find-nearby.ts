import { Inject, Injectable } from '@nestjs/common';
import { type ProviderQuery, type ProviderRecord } from '../contract/admin-search';
import { type Candidate, rank } from '../domain/nearby';
import { type Point } from '../domain/provider';
import { CATALOG, type Catalog } from '../port/peers';
import { PRESENCE, type Presence } from '../port/presence';
import {
  PROVIDER_REPOSITORY,
  type ProviderRepository,
  type RadiusCandidate,
} from '../port/repository';

/** A search for providers around a customer. */
export interface Nearby {
  readonly serviceId: string;
  readonly at: Point;
  readonly radiusM: number;
  readonly womenOnly: boolean;
  readonly byRating: boolean;
  readonly limit: number;
}

/**
 * Keeps candidates within their own working radius and, for women-only services, women
 * providers (D11).
 */
function eligible(rows: RadiusCandidate[], dist: Map<string, number>, womenOnly: boolean) {
  const out: Candidate[] = [];
  for (const { workingRadiusM, ...c } of rows) {
    const distanceM = dist.get(c.id) ?? 0;
    if (distanceM <= workingRadiusM && (!womenOnly || c.gender === 'female')) {
      out.push({ ...c, distanceM });
    }
  }
  return out;
}

/** Finds providers for customers and lists them for admins. */
@Injectable()
export class FindProviders {
  constructor(
    @Inject(PROVIDER_REPOSITORY) private readonly repo: ProviderRepository,
    @Inject(PRESENCE) private readonly presence: Presence,
    @Inject(CATALOG) private readonly catalog: Catalog,
  ) {}

  /**
   * Online providers who may take the service, within both the search radius and their
   * own working radius, Level 2 first (PRD §5, D11).
   */
  async nearby(q: Nearby): Promise<Candidate[]> {
    const svc = await this.catalog.service(q.serviceId);
    const hits = await this.presence.near(q.serviceId, q.at, q.radiusM);
    if (hits.length === 0) {
      return [];
    }
    const dist = new Map(hits.map((h) => [h.id, h.distanceM]));
    const rows = await this.repo.candidates([...dist.keys()], Math.max(1, svc.minLevel));
    const out = rank(eligible(rows, dist, q.womenOnly || svc.womenProvidersOnly), q.byRating);
    return q.limit > 0 ? out.slice(0, q.limit) : out;
  }

  /** Lists providers for the admin console with their live online flag (A-05). */
  async search(q: ProviderQuery): Promise<ProviderRecord[]> {
    const out: ProviderRecord[] = [];
    for (const r of await this.repo.search(q)) {
      out.push({ ...r, online: await this.presence.isOnline(r.id) });
    }
    return out;
  }
}
