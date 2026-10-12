import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { BookingEvents, type BookingRequested } from '../contract/events';
import { type Booking, type Line, total } from '../domain/booking';
import { BookingReasons } from '../domain/reasons';
import { Actor, Status } from '../domain/states';
import { type Service, SETTINGS, type Settings } from '../port/peers';
import { BookingAccess } from './access';
import { Eligibility } from './eligibility';
import { type Item, Pricing } from './pricing';

/** A customer's booking request. */
export interface CreateInput {
  readonly customerId: string;
  readonly providerId: string;
  readonly serviceId: string;
  readonly addressId: string;
  readonly items: readonly Item[];
  readonly scheduledAt: Date | null;
  readonly note: string;
  readonly idempotencyKey: string;
}

const HOUR_MS = 3_600_000;

function invalid(in_: CreateInput, now: Date): boolean {
  return (
    in_.idempotencyKey.trim() === '' ||
    in_.items.length === 0 ||
    in_.items.length > 10 ||
    Array.from(in_.note).length > 500 ||
    (in_.scheduledAt !== null && in_.scheduledAt <= now)
  );
}

/** The end of a duration hire: the start plus the booked hours or days. */
function endsAt(svc: Service, start: Date, lines: readonly Line[]): Date | null {
  const first = lines[0];
  if (svc.model !== 'duration_hire' || first === undefined) {
    return null;
  }
  const end = new Date(start);
  if (first.unit === 'day') {
    end.setUTCDate(end.getUTCDate() + first.quantity);
  } else {
    end.setTime(end.getTime() + first.quantity * HOUR_MS);
  }
  return end;
}

/** Records booking requests with every snapshot copied in (PRD §5, §9.3 rule 4). */
@Injectable()
export class CreateBooking {
  constructor(
    private readonly access: BookingAccess,
    private readonly pricing: Pricing,
    private readonly eligibility: Eligibility,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** Creates the request; a repeated idempotency key returns the stored booking (PRD §9.6). */
  async execute(in_: CreateInput): Promise<{ booking: Booking; created: boolean }> {
    const now = this.access.clock.now();
    if (invalid(in_, now)) {
      throw new DomainError(BookingReasons.Invalid);
    }
    const b = await this.draft(in_, now);
    return this.access.repo.create(b, (stored): BookingRequested => ({
      name: BookingEvents.BookingRequested,
      ...this.access.parties(stored),
      acceptDeadline: stored.acceptDeadline.toISOString(),
      scheduled: stored.scheduled,
      totalPaisa: stored.totalPaisa,
    }));
  }

  private async draft(in_: CreateInput, now: Date): Promise<Booking> {
    const svc = await this.pricing.service(in_.serviceId);
    const lines = await this.pricing.lines(in_.serviceId, in_.items);
    const { cust, prov } = await this.eligibility.sides(in_);
    const rules = await this.settings.rules();
    const scheduled = in_.scheduledAt !== null;
    const wait = scheduled ? rules.acceptScheduledMs : rules.acceptAsapMs;
    const entry = {
      id: this.access.ids.newId(),
      status: Status.Requested,
      actor: Actor.Customer,
      reason: '',
      at: now,
    };
    return {
      ...blank(),
      id: this.access.ids.newId(),
      customer: { id: in_.customerId, name: cust.name, phone: cust.phone },
      provider: { id: in_.providerId, name: prov.name, phone: prov.phone },
      serviceId: svc.id,
      serviceName: svc.name,
      serviceModel: svc.model,
      address: cust.address,
      note: in_.note.trim(),
      scheduled,
      scheduledAt: in_.scheduledAt,
      endsAt: endsAt(svc, in_.scheduledAt ?? now, lines),
      acceptDeadline: new Date(now.getTime() + wait),
      totalPaisa: total(lines),
      idempotencyKey: in_.idempotencyKey,
      createdAt: now,
      lines,
      timeline: [entry],
      newEvents: [entry],
    };
  }
}

/** The fields a new booking starts without. */
function blank(): Pick<
  Booking,
  | 'number'
  | 'status'
  | 'startCode'
  | 'codeAttempts'
  | 'codeLockedUntil'
  | 'cashReceived'
  | 'cancelReason'
  | 'cancelledBy'
  | 'rejectReason'
  | 'acceptedAt'
  | 'startedAt'
  | 'completedAt'
  | 'cancelledAt'
  | 'proposals'
  | 'providerActiveJobs'
> {
  return {
    number: 0,
    status: Status.Requested,
    startCode: '',
    codeAttempts: 0,
    codeLockedUntil: null,
    cashReceived: false,
    cancelReason: '',
    cancelledBy: '',
    rejectReason: '',
    acceptedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
    proposals: [],
    providerActiveJobs: 0,
  };
}
