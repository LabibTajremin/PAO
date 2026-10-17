import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { BookingEvents } from '../contract/events';
import { type Booking, pending, type Proposal } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import { Status } from '../domain/states';
import { advance, complete, decide, propose, type Refusal, start } from '../domain/transitions';
import { SETTINGS, type Settings } from '../port/peers';
import { BookingAccess, refuse } from './access';
import { type Item, Pricing } from './pricing';

/** The job from the provider setting off to completion, with extras (PRD §5). */
@Injectable()
export class ProgressJob {
  constructor(
    private readonly access: BookingAccess,
    private readonly pricing: Pricing,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** Transitions 5 (on the way) and 6 (arrived). */
  advance(provider: string, id: string, to: Status): Promise<Booking> {
    return this.access.asProvider(id, provider, (b) => {
      refuse(advance(b, to, this.access.stamp()));
      const name =
        to === Status.OnTheWay ? BookingEvents.ProviderOnTheWay : BookingEvents.ProviderArrived;
      return [{ name, ...this.access.parties(b) }];
    });
  }

  /**
   * Transition 7. A wrong code is saved before it is reported, so the lockout survives
   * retries.
   */
  async start(provider: string, id: string, code: string): Promise<Booking> {
    const rules = await this.settings.rules();
    const limits = { maxAttempts: rules.startCodeMaxAttempts, lockoutMs: rules.startCodeLockoutMs };
    let wrong: Refusal;
    const b = await this.access.asProvider(id, provider, (b) => {
      const refused = start(b, code, this.access.stamp(), limits);
      if (refused === BookingReasons.CodeWrong) {
        wrong = refused;
        return [];
      }
      refuse(refused);
      return [{ name: BookingEvents.BookingStarted, ...this.access.parties(b) }];
    });
    refuse(wrong);
    return b;
  }

  /** Adds catalog items of the booked service for the customer to approve. */
  async proposeExtras(provider: string, id: string, items: readonly Item[]): Promise<Booking> {
    if (items.length === 0 || items.length > 10) {
      throw new DomainError(BookingReasons.Invalid);
    }
    return this.access.change(id, { party: provider, side: 'provider' }, async (b) => {
      const lines = await this.pricing.lines(b.serviceId, items, true);
      const p: Proposal = {
        id: this.access.ids.newId(),
        status: 'pending',
        addedPaisa: 0,
        proposedAt: this.access.clock.now(),
        decidedAt: null,
        lines,
      };
      // Positions continue after the bill and every proposal not already on it.
      const next = b.proposals
        .filter((old) => old.status !== 'approved')
        .reduce((n, old) => n + old.lines.length, b.lines.length);
      p.lines.forEach((l, i) => Object.assign(l, { proposalId: p.id, position: next + i }));
      refuse(propose(b, p));
      const added = pending(b)?.addedPaisa ?? 0;
      const e = {
        name: BookingEvents.ExtraItemsProposed,
        ...this.access.parties(b),
        proposalId: p.id,
        addedPaisa: added,
        newTotalPaisa: b.totalPaisa + added,
      };
      return [e];
    });
  }

  /** The customer's answer to a proposal. */
  decideExtras(customer: string, id: string, proposalId: string, approve: boolean) {
    return this.access.change(id, { party: customer, side: 'customer' }, (b) => {
      refuse(decide(b, proposalId, approve, this.access.clock.now()));
      const e = {
        name: BookingEvents.ExtraItemsDecided,
        ...this.access.parties(b),
        proposalId,
        approved: approve,
      };
      return Promise.resolve<DomainEvent[]>([e]);
    });
  }

  /** Transition 8 (D4: cash confirmed). */
  complete(provider: string, id: string, cash: boolean): Promise<Booking> {
    return this.access.asProvider(id, provider, (b) => {
      refuse(complete(b, cash, this.access.stamp()));
      const e = {
        name: BookingEvents.BookingCompleted,
        ...this.access.parties(b),
        totalPaisa: b.totalPaisa,
        customerName: b.customer.name,
        providerName: b.provider.name,
        serviceName: b.serviceName,
      };
      return [e];
    });
  }
}
