import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { type BookingParties } from '../contract/events';
import { type Booking } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import { type Refusal, type Stamp } from '../domain/transitions';
import { BOOKING_REPOSITORY, type BookingRepository, type Change } from '../port/repository';

/** Formats a booking number for people (e.g. PAO-104233). */
export function bookingNumber(n: number): string {
  return `PAO-${String(n)}`;
}

/** Throws the refusal of a domain rule. */
export function refuse(r: Refusal): void {
  if (r !== undefined) {
    throw new DomainError(r);
  }
}

/** Which side of the booking a caller acts as. */
export type Side = 'customer' | 'provider';

/**
 * Loads and changes bookings for one party, hiding other people's bookings as not found,
 * and stamps the events every use case publishes.
 */
@Injectable()
export class BookingAccess {
  constructor(
    @Inject(BOOKING_REPOSITORY) readonly repo: BookingRepository,
    @Inject(CLOCK) readonly clock: Clock,
    @Inject(ID_GENERATOR) readonly ids: IdGenerator,
  ) {}

  /** A timeline stamp for now. */
  stamp(): Stamp {
    return { now: this.clock.now(), id: this.ids.newId() };
  }

  /** Who the booking's events concern. */
  parties(b: Booking): BookingParties {
    return {
      bookingId: b.id,
      number: bookingNumber(b.number),
      customerId: b.customer.id,
      providerId: b.provider.id,
      serviceId: b.serviceId,
      at: this.clock.now().toISOString(),
    };
  }

  /** A booking the party takes part in, on the given side when one is named. */
  async owned(id: string, party: string, side?: Side): Promise<Booking> {
    const b = await this.repo.get(id);
    if (!takesPart(b, party, side)) {
      throw new DomainError(BookingReasons.NotFound);
    }
    return b;
  }

  /** Applies `fn` to a booking the party takes part in on `side`. */
  change(id: string, who: { party: string; side: Side }, fn: Change): Promise<Booking> {
    return this.repo.change(id, (b) => {
      if (!takesPart(b, who.party, who.side)) {
        throw new DomainError(BookingReasons.NotFound);
      }
      return fn(b);
    });
  }

  /** Applies a provider-side change and publishes the event `fn` returns. */
  asProvider(id: string, provider: string, fn: (b: Booking) => DomainEvent[]): Promise<Booking> {
    return this.change(id, { party: provider, side: 'provider' }, (b) => Promise.resolve(fn(b)));
  }
}

function takesPart(b: Booking, party: string, side?: Side): boolean {
  if (side === 'customer') {
    return b.customer.id === party;
  }
  if (side === 'provider') {
    return b.provider.id === party;
  }
  return b.customer.id === party || b.provider.id === party;
}
