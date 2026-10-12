import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { type Line, newLine, type Point } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import { CATALOG, type Catalog, CUSTOMERS, type Customers, type Service } from '../port/peers';

/** One requested sub-service. */
export interface Item {
  readonly subServiceId: string;
  readonly quantity: number;
}

const BOOKABLE_MODELS = ['on_demand', 'duration_hire'];

/** Prices items from the current catalog and checks services and the launch area. */
@Injectable()
export class Pricing {
  constructor(
    @Inject(CATALOG) private readonly catalog: Catalog,
    @Inject(CUSTOMERS) private readonly customers: Customers,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /**
   * A published, bookable service; listing and referral services are not booked
   * directly.
   */
  async service(id: string): Promise<Service> {
    const s = await this.catalog.service(id);
    if (!s.published || !BOOKABLE_MODELS.includes(s.model)) {
      throw new DomainError(BookingReasons.NotBookable);
    }
    return s;
  }

  /** Prices `items`; every item must be a published sub-service of the booked service. */
  async lines(serviceId: string, items: readonly Item[], extra = false): Promise<Line[]> {
    const out: Line[] = [];
    for (const [position, it] of items.entries()) {
      out.push({ ...(await this.line(serviceId, it)), position, extra });
    }
    return out;
  }

  /** Prices one item at position 0. */
  async line(serviceId: string, it: Item): Promise<Line> {
    const p = await this.catalog.price(it.subServiceId);
    const line =
      p.published && p.serviceId === serviceId
        ? newLine({ ...p, id: this.ids.newId(), unitPaisa: p.amountPaisa }, it.quantity)
        : undefined;
    if (line === undefined) {
      throw new DomainError(BookingReasons.Invalid);
    }
    return line;
  }

  /** Throws `booking.outside_area` outside the launch area (D5). */
  async covered(p: Point): Promise<void> {
    if (!(await this.customers.covered(p))) {
      throw new DomainError(BookingReasons.OutsideArea);
    }
  }
}
