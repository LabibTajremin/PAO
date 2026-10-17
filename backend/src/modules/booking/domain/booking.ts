import { ACTIVE, Actor, canTransition, Status } from './states';

/** A value in English and Bangla. */
export interface Text {
  readonly en: string;
  readonly bn: string;
}

/** A WGS84 position. */
export interface Point {
  readonly lat: number;
  readonly lng: number;
}

/** A priced item copied from the catalog (PRD §9.3 rule 4). */
export interface Line {
  readonly id: string;
  readonly subServiceId: string;
  readonly priceVersionId: string;
  readonly name: Text;
  readonly unit: string;
  readonly quantity: number;
  readonly unitPaisa: number;
  readonly totalPaisa: number;
  extra: boolean;
  proposalId: string | null;
  position: number;
}

/** A catalog price a line is made from. */
export interface PriceTag {
  readonly id: string;
  readonly subServiceId: string;
  readonly priceVersionId: string;
  readonly name: Text;
  readonly unit: string;
  readonly unitPaisa: number;
  /** Zero means no limit. */
  readonly maxQuantity: number;
}

/** Where an extras proposal stands. */
export type ProposalStatus = 'pending' | 'approved' | 'declined';

/** A set of extra items waiting for the customer. */
export interface Proposal {
  readonly id: string;
  status: ProposalStatus;
  addedPaisa: number;
  readonly proposedAt: Date;
  decidedAt: Date | null;
  readonly lines: Line[];
}

/** One timeline entry. */
export interface TimelineEntry {
  readonly id: string;
  readonly status: string;
  readonly actor: string;
  readonly reason: string;
  readonly at: Date;
}

/** A snapshot of one side of the booking. */
export interface Party {
  readonly id: string;
  name: string;
  phone: string;
}

/** The service address snapshot. */
export interface Address {
  readonly id: string;
  readonly area: string;
  readonly line1: string;
  readonly line2: string;
  readonly location: Point;
}

/** The aggregate moved by the state machine. */
export interface Booking {
  readonly id: string;
  number: number;
  readonly customer: Party;
  readonly provider: Party;
  readonly serviceId: string;
  readonly serviceName: Text;
  readonly serviceModel: string;
  readonly address: Address;
  readonly note: string;
  status: Status;
  readonly scheduled: boolean;
  readonly scheduledAt: Date | null;
  endsAt: Date | null;
  acceptDeadline: Date;
  totalPaisa: number;
  startCode: string;
  codeAttempts: number;
  codeLockedUntil: Date | null;
  cashReceived: boolean;
  readonly idempotencyKey: string;
  cancelReason: string;
  cancelledBy: string;
  rejectReason: string;
  readonly createdAt: Date;
  acceptedAt: Date | null;
  startedAt: Date | null;
  completedAt: Date | null;
  cancelledAt: Date | null;
  lines: Line[];
  readonly proposals: Proposal[];
  readonly timeline: TimelineEntry[];
  /** The provider's other active jobs, counted under the provider lock. */
  providerActiveJobs: number;
  /** Timeline entries added since loading. */
  readonly newEvents: TimelineEntry[];
}

/** Prices a line, or returns undefined for a quantity outside 1..maxQuantity. */
export function newLine(price: PriceTag, quantity: number): Line | undefined {
  if (quantity < 1 || (price.maxQuantity > 0 && quantity > price.maxQuantity)) {
    return undefined;
  }
  const { id, subServiceId, priceVersionId, name, unit, unitPaisa } = price;
  return {
    id,
    subServiceId,
    priceVersionId,
    name,
    unit,
    quantity,
    unitPaisa,
    totalPaisa: unitPaisa * quantity,
    extra: false,
    proposalId: null,
    position: 0,
  };
}

/** Sums the lines. */
export function total(lines: readonly Line[]): number {
  return lines.reduce((sum, l) => sum + l.totalPaisa, 0);
}

/** The proposal waiting for the customer, if any. */
export function pending(b: Pick<Booking, 'proposals'>): Proposal | undefined {
  return b.proposals.find((p) => p.status === 'pending');
}

/** Reports whether the customer may still cancel: until the start code is entered (D8). */
export function cancellable(b: Pick<Booking, 'status'>, actor: Actor = Actor.Customer): boolean {
  return canTransition(b.status, Status.Cancelled, actor);
}

/**
 * Reports whether contact details and the exact address are visible to the other side:
 * only after acceptance and while the job is live or done (PRD §5, §11).
 */
export function contactsShared(b: Pick<Booking, 'acceptedAt' | 'status'>): boolean {
  return b.acceptedAt !== null && (ACTIVE.includes(b.status) || b.status === Status.Completed);
}
