import { type VerificationReason, VerificationReasons } from './reasons';

/** Item statuses. */
export const ItemStatus = {
  Missing: 'missing',
  Pending: 'pending',
  Approved: 'approved',
  Rejected: 'rejected',
  Expired: 'expired',
} as const;

/** Every item in display order; skill proof is optional (PRD §6.2). */
export const ITEM_TYPES = [
  'nid',
  'selfie',
  'police_clearance',
  'address',
  'emergency_contact',
  'skill_proof',
  'service_area',
  'code_of_conduct',
] as const;

/** Reports whether Level 1 needs the item approved. */
export function required(itemType: string): boolean {
  return itemType !== 'skill_proof';
}

/** One requirement's review state. */
export interface Item {
  readonly type: string;
  readonly status: string;
  readonly reason: string;
  readonly fields: Readonly<Record<string, string>>;
  readonly submittedAt: Date | null;
  readonly decidedAt: Date | null;
  readonly decidedBy: string | null;
  readonly expiresAt: Date | null;
}

/** An item never submitted. */
export function missingItem(type: string): Item {
  return {
    type,
    status: ItemStatus.Missing,
    reason: '',
    fields: {},
    submittedAt: null,
    decidedAt: null,
    decidedBy: null,
    expiresAt: null,
  };
}

/** The item back in the review queue with new data. */
export function submitted(
  it: Item,
  now: Date,
  fields: Readonly<Record<string, string>>,
  expiresAt: Date | null,
): Item {
  return {
    ...it,
    status: ItemStatus.Pending,
    reason: '',
    fields,
    submittedAt: now,
    decidedAt: null,
    decidedBy: null,
    expiresAt,
  };
}

/** A verifier's decision on one item. */
export interface Decision {
  readonly now: Date;
  readonly actor: string;
  readonly approve: boolean;
  readonly reason: string;
}

/**
 * Approves or rejects a pending item; approved items may also be rejected when a
 * verifier finds a problem later.
 */
export function decided(it: Item, d: Decision): Item | VerificationReason {
  const open = it.status === ItemStatus.Pending;
  if (!open && (d.approve || it.status !== ItemStatus.Approved)) {
    return VerificationReasons.NotPending;
  }
  const outcome = d.approve
    ? { status: ItemStatus.Approved, reason: '' }
    : { status: ItemStatus.Rejected, reason: d.reason };
  return { ...it, ...outcome, decidedAt: d.now, decidedBy: d.actor };
}

/** Reports whether an approved item's validity has ended (PRD §6.4). */
export function hasExpired(it: Item, now: Date): boolean {
  return it.status === ItemStatus.Approved && it.expiresAt !== null && it.expiresAt <= now;
}

/** Level 1 when every required item is approved, 2 when Level 2 was passed too (PRD §6.1). */
export function level(items: ReadonlyMap<string, Item>, level2Passed: boolean): number {
  const approved = ITEM_TYPES.every(
    (t) => !required(t) || items.get(t)?.status === ItemStatus.Approved,
  );
  if (!approved) {
    return 0;
  }
  return level2Passed ? 2 : 1;
}

/**
 * Checks a police clearance issue date against `today` and returns when the certificate
 * stops counting (issue date plus validity).
 */
export function clearanceExpiry(issued: Date, today: Date, validityMs: number): Date | undefined {
  const expires = new Date(issued.getTime() + validityMs);
  return issued > today || expires <= today ? undefined : expires;
}

/** Accepts the 10, 13 and 17 digit NID formats. */
export function validNid(n: string): boolean {
  return /^(?:\d{10}|\d{13}|\d{17})$/.test(n);
}

const DAY_MS = 24 * 60 * 60 * 1000;
const DHAKA_OFFSET_MS = 6 * 60 * 60 * 1000;

/**
 * The calendar date in Dhaka at `now`, as midnight UTC, so it compares directly with
 * dates parsed from "YYYY-MM-DD" (04-decisions E8).
 */
export function dhakaDate(now: Date): Date {
  const local = now.getTime() + DHAKA_OFFSET_MS;
  return new Date(local - (local % DAY_MS));
}
