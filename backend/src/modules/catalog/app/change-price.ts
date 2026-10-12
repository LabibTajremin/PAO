import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { CatalogEvents } from '../contract/events';
import { isValidPrice, type PriceVersion } from '../domain/catalog';
import { CatalogReason } from '../domain/errors';
import { CATALOG_REPOSITORY, type CatalogRepository } from '../port/catalog-repository';
import { check } from './check';
import { recordChange } from './record-change';

/**
 * Prices are immutable versions: a change inserts a new one and bookings keep the
 * version they copied (PRD §4).
 */
@Injectable()
export class ChangePrice {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repo: CatalogRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Makes `amount` the sub-service's current price, set by `actorId`. */
  async change(subServiceId: string, amount: number, actorId: string): Promise<PriceVersion> {
    check(isValidPrice(amount), CatalogReason.PriceNegative);
    await this.repo.subService(subServiceId);
    const price = {
      id: this.ids.newId(),
      subServiceId,
      amount,
      effectiveFrom: this.clock.now(),
      createdBy: actorId,
    };
    await recordChange(this.repo, async (w) => {
      await w.addPrice(price);
      await w.publish(subServiceId, {
        name: CatalogEvents.PriceChanged,
        subServiceId,
        priceVersionId: price.id,
        amountPaisa: amount,
        actorId,
      });
    });
    return price;
  }

  /** A sub-service's price versions, newest first. */
  async history(subServiceId: string): Promise<PriceVersion[]> {
    await this.repo.subService(subServiceId);
    return this.repo.priceHistory(subServiceId);
  }
}
