import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type Line, type Point } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import {
  CUSTOMERS,
  type Customers,
  FINDER,
  type Finder,
  MEDIA,
  type Media,
  type Nearby,
} from '../port/peers';
import { Pricing } from './pricing';

/** A customer's provider search (C10). */
export interface NearbyQuery {
  readonly customerId: string;
  readonly serviceId: string;
  readonly subServiceId: string;
  readonly quantity: number;
  readonly addressId: string | null;
  readonly at: Point | null;
  readonly byRating: boolean;
  readonly limit: number;
}

/** A provider in the result, with a signed photo URL when there is one. */
export interface Card extends Nearby {
  readonly photoUrl: string;
}

/** The fixed price and the providers who can do the job. */
export interface NearbyResult {
  readonly price: Line;
  readonly providers: Card[];
}

/** Prices a sub-service and lists verified, online providers around the customer (PRD §5). */
@Injectable()
export class FindNearby {
  constructor(
    private readonly pricing: Pricing,
    @Inject(CUSTOMERS) private readonly customers: Customers,
    @Inject(FINDER) private readonly finder: Finder,
    @Inject(MEDIA) private readonly media: Media,
  ) {}

  async execute(q: NearbyQuery): Promise<NearbyResult> {
    const svc = await this.pricing.service(q.serviceId);
    const item = { subServiceId: q.subServiceId, quantity: q.quantity };
    const price = await this.pricing.line(q.serviceId, item);
    const at = await this.where(q);
    await this.pricing.covered(at);
    const found = await this.finder.findNearby({
      serviceId: q.serviceId,
      at,
      radiusM: svc.searchRadiusM,
      womenOnly: svc.womenProvidersOnly,
      byRating: q.byRating,
      limit: q.limit,
    });
    const providers = await Promise.all(found.map((n) => this.card(q.customerId, n)));
    return { price, providers };
  }

  private async where(q: NearbyQuery): Promise<Point> {
    if (q.addressId !== null) {
      return (await this.customers.address(q.customerId, q.addressId)).location;
    }
    if (q.at === null) {
      throw new DomainError(BookingReasons.Invalid);
    }
    return q.at;
  }

  /** A photo that cannot be signed is left out; the card still works without it. */
  private async card(viewer: string, n: Nearby): Promise<Card> {
    const photoUrl =
      n.photoMediaId === null ? '' : await this.media.url(viewer, n.photoMediaId).catch(() => '');
    return { ...n, photoUrl };
  }
}
