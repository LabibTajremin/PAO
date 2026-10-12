import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { type Item, type ItemType } from '../contract/dto';
import { type ProviderLevelChanged, VerificationEvents } from '../contract/events';
import { required } from '../domain/items';
import { canReceiveBookings, recalc, type State } from '../domain/state';
import { CATALOG, type Catalog } from '../port/peers';
import {
  type Change,
  VERIFICATION_REPOSITORY,
  type VerificationRepository,
} from '../port/repository';

/** Provider states, their levels and the time and id sources changes are stamped with. */
@Injectable()
export class States {
  constructor(
    @Inject(VERIFICATION_REPOSITORY) readonly repo: VerificationRepository,
    @Inject(CATALOG) readonly catalog: Catalog,
    @Inject(CLOCK) readonly clock: Clock,
    @Inject(ID_GENERATOR) readonly ids: IdGenerator,
  ) {}

  /**
   * Applies `fn` and recomputes the level in the same transaction, publishing
   * ProviderLevelChanged whenever the level moves (PRD §6.1).
   */
  change(id: string, reason: string, fn: Change): Promise<State> {
    return this.repo.change(id, async (st) => {
      const events = await fn(st);
      const from = recalc(st);
      if (from !== undefined) {
        const moved: ProviderLevelChanged = {
          name: VerificationEvents.ProviderLevelChanged,
          providerId: id,
          from,
          to: st.level,
          reason,
        };
        events.push(moved);
      }
      return events;
    });
  }

  /** A provider's level; 0 when verification has never seen them. */
  async level(id: string): Promise<number> {
    return (await this.repo.load(id)).level;
  }

  /** Levels of many providers; unknown ones are absent. */
  levels(ids: readonly string[]): Promise<Map<string, number>> {
    return this.repo.levels(ids);
  }

  /** Applies the level rules for a service; null asks about any service (PRD §6.1, §6.4). */
  async canReceiveBookings(id: string, serviceId: string | null): Promise<boolean> {
    const st = await this.repo.load(id);
    const minLevel = serviceId === null ? 0 : (await this.catalog.service(serviceId)).minLevel;
    return canReceiveBookings(st, minLevel);
  }

  /** The provider's items for the admin provider record, sorted by type (A-05). */
  async items(id: string): Promise<Item[]> {
    const st = await this.repo.load(id);
    return [...st.items.values()]
      .map((it) => ({
        type: it.type as ItemType,
        status: it.status,
        reason: it.reason,
        required: required(it.type),
        decidedAt: it.decidedAt,
        expiresAt: it.expiresAt,
      }))
      .sort((a, b) => (a.type < b.type ? -1 : 1));
  }

  /** Providers waiting in the review queue (A-09). */
  countPendingReviews(): Promise<number> {
    return this.repo.countPendingReviews();
  }
}
