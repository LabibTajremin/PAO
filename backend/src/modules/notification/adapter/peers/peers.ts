import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { isDomainError } from '../../../../platform/errors/domain-error';
import { BOOKING_SERVICE, type BookingService } from '../../../booking/contract/booking-service';
import { BookingErrors } from '../../../booking/contract/errors';
import {
  CUSTOMER_SERVICE,
  type CustomerService,
} from '../../../customer/contract/customer-service';
import {
  PROVIDER_SERVICE,
  type ProviderService,
} from '../../../provider/contract/provider-service';
import { App } from '../../domain/notification';
import { type BookingFacts, type Bookings, type Languages } from '../../port/ports';

// Contracts are resolved on first use: booking and the profiles notify through this
// module, so a direct dependency would be a cycle.

/** Reads languages from the customer and provider profiles. */
@Injectable()
export class ProfileLanguages implements Languages {
  private readonly customers: LazyContract<CustomerService>;
  private readonly providers: LazyContract<ProviderService>;

  constructor(ref: ModuleRef) {
    this.customers = new LazyContract(ref, CUSTOMER_SERVICE);
    this.providers = new LazyContract(ref, PROVIDER_SERVICE);
  }

  /** Bangla is the default for anyone without a profile (04-decisions.md). */
  async language(account: string, app: App): Promise<string> {
    try {
      if (app === App.Customer) {
        return (await this.customers.get().getCustomer(account)).language;
      }
      return (await this.providers.get().getProvider(account)).language;
    } catch {
      return 'bn';
    }
  }
}

/** Reads booking details through the booking contract. */
@Injectable()
export class BookingDetails implements Bookings {
  private readonly bookings: LazyContract<BookingService>;

  constructor(ref: ModuleRef) {
    this.bookings = new LazyContract(ref, BOOKING_SERVICE);
  }

  async booking(id: string): Promise<BookingFacts | undefined> {
    try {
      const b = await this.bookings.get().getBooking(id);
      return {
        number: b.number,
        serviceEn: b.serviceName.en,
        serviceBn: b.serviceName.bn,
        area: b.area,
        providerName: b.providerName,
        customerName: b.customerName,
      };
    } catch (err) {
      if (isDomainError(err, BookingErrors.NotFound)) {
        return undefined;
      }
      throw err;
    }
  }
}
