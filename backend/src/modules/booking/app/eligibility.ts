import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { BookingReasons } from '../domain/reasons';
import {
  type Customer,
  CUSTOMERS,
  type Customers,
  type Provider,
  PROVIDERS,
  type Providers,
} from '../port/peers';
import { Pricing } from './pricing';

/** Who a booking request is between. */
export interface Sides {
  readonly customerId: string;
  readonly addressId: string;
  readonly providerId: string;
  readonly serviceId: string;
}

/** Checks that both sides of a new booking may take part in it. */
@Injectable()
export class Eligibility {
  constructor(
    private readonly pricing: Pricing,
    @Inject(CUSTOMERS) private readonly customers: Customers,
    @Inject(PROVIDERS) private readonly providers: Providers,
  ) {}

  /**
   * Loads both parties: the customer's address must be in the launch area and the
   * provider must offer the service, be allowed to take it and be online.
   */
  async sides(in_: Sides): Promise<{ cust: Customer; prov: Provider }> {
    const cust = await this.customers.customer(in_.customerId, in_.addressId);
    await this.pricing.covered(cust.address.location);
    const prov = await this.providers.provider(in_.providerId);
    const ok =
      prov.serviceIds.includes(in_.serviceId) &&
      (await this.providers.canReceiveBookings(in_.providerId, in_.serviceId)) &&
      (await this.providers.isAvailable(in_.providerId));
    if (!ok) {
      throw new DomainError(BookingReasons.NotBookable);
    }
    return { cust, prov };
  }
}
