import { Inject, Injectable } from '@nestjs/common';
import { type DomainEvent } from '../../../platform/events/domain-event';
import {
  type BookingAccepted,
  type BookingCancelled,
  BookingEvents,
  type BookingRejected,
  type BookingTimedOut,
} from '../contract/events';
import { type Booking } from '../domain/booking';
import { type Actor } from '../domain/states';
import { accept, cancel, reject, timeOut } from '../domain/transitions';
import { START_CODES, type StartCodes } from '../port/peers';
import { BookingAccess, refuse } from './access';

/** The provider's answer to a request, the timeout sweep and cancellations. */
@Injectable()
export class RespondToRequests {
  constructor(
    private readonly access: BookingAccess,
    @Inject(START_CODES) private readonly codes: StartCodes,
  ) {}

  /** Transition 1; the start code is made now and shown only to the customer. */
  accept(provider: string, id: string): Promise<Booking> {
    return this.access.asProvider(id, provider, (b) => {
      refuse(accept(b, this.access.stamp()));
      b.startCode = this.codes.next();
      const e: BookingAccepted = { name: BookingEvents.BookingAccepted, ...this.access.parties(b) };
      return [e];
    });
  }

  /** Transition 2. */
  reject(provider: string, id: string, reason: string): Promise<Booking> {
    return this.access.asProvider(id, provider, (b) => {
      refuse(reject(b, this.access.stamp(), reason));
      const e: BookingRejected = {
        name: BookingEvents.BookingRejected,
        ...this.access.parties(b),
        reason,
      };
      return [e];
    });
  }

  /** Times out every request past its deadline (transition 3, D12). */
  async expireDue(): Promise<void> {
    const now = this.access.clock.now();
    for (const id of await this.access.repo.due(now)) {
      await this.access.repo.change(id, (b) => {
        // A provider answering at the same moment already moved the booking on.
        if (timeOut(b, { now, id: this.access.ids.newId() }) !== undefined) {
          return Promise.resolve([]);
        }
        const e: BookingTimedOut = {
          name: BookingEvents.BookingTimedOut,
          ...this.access.parties(b),
        };
        return Promise.resolve([e]);
      });
    }
  }

  /** Transitions 4, 9 and 10. Reasons are stored as "reason: note". */
  cancel(actor: Actor & ('customer' | 'provider'), party: string, id: string, reason: string) {
    return this.access.change(id, { party, side: actor }, (b) => {
      refuse(cancel(b, this.access.stamp(), actor, reason));
      const e: BookingCancelled = {
        name: BookingEvents.BookingCancelled,
        ...this.access.parties(b),
        by: actor,
        reason,
        afterAcceptance: b.acceptedAt !== null,
      };
      return Promise.resolve<DomainEvent[]>([e]);
    });
  }
}
