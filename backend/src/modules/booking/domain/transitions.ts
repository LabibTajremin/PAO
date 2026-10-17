import { type Booking, pending, type Proposal, total } from './booking';
import { type BookingReason, BookingReasons } from './reasons';
import { Actor, canTransition, Status } from './states';

/** When a change happens and the id of the timeline entry it records. */
export interface Stamp {
  readonly now: Date;
  readonly id: string;
}

/** The start-code rules from the admin settings (D12). */
export interface CodeLimits {
  readonly maxAttempts: number;
  readonly lockoutMs: number;
}

/** Why a change was refused; undefined means it happened. */
export type Refusal = BookingReason | undefined;

function move(b: Booking, step: { to: Status; actor: Actor; reason?: string }, s: Stamp): Refusal {
  const { to, actor, reason = '' } = step;
  if (!canTransition(b.status, to, actor)) {
    return BookingReasons.InvalidTransition;
  }
  b.status = to;
  const entry = { id: s.id, status: to, actor, reason, at: s.now };
  b.timeline.push(entry);
  b.newEvents.push(entry);
  return undefined;
}

function pastDeadline(b: Booking, now: Date): boolean {
  return b.status === Status.Requested && now >= b.acceptDeadline;
}

/**
 * Transition 1: before the deadline, and for an ASAP booking only when the provider has
 * no other active job (PRD §5).
 */
export function accept(b: Booking, s: Stamp): Refusal {
  if (pastDeadline(b, s.now)) {
    return BookingReasons.DeadlinePassed;
  }
  if (b.status === Status.Requested && !b.scheduled && b.providerActiveJobs > 0) {
    return BookingReasons.ActiveJob;
  }
  const refused = move(b, { to: Status.Accepted, actor: Actor.Provider }, s);
  if (refused === undefined) {
    b.acceptedAt = s.now;
  }
  return refused;
}

/** Transition 2. */
export function reject(b: Booking, s: Stamp, reason: string): Refusal {
  if (pastDeadline(b, s.now)) {
    return BookingReasons.DeadlinePassed;
  }
  const refused = move(b, { to: Status.Rejected, actor: Actor.Provider, reason }, s);
  if (refused === undefined) {
    b.rejectReason = reason;
  }
  return refused;
}

/** Transition 3, applied by the expiry job once the deadline passed. */
export function timeOut(b: Booking, s: Stamp): Refusal {
  if (s.now < b.acceptDeadline) {
    return BookingReasons.InvalidTransition;
  }
  return move(b, { to: Status.TimedOut, actor: Actor.System }, s);
}

/** Transitions 4, 9 and 10; nobody may cancel once the job started (D8). */
export function cancel(b: Booking, s: Stamp, actor: Actor, reason: string): Refusal {
  if (b.status === Status.InProgress || b.status === Status.Completed) {
    return BookingReasons.CancelNotAllowed;
  }
  const refused = move(b, { to: Status.Cancelled, actor, reason }, s);
  if (refused === undefined) {
    b.cancelReason = reason;
    b.cancelledBy = actor;
    b.cancelledAt = s.now;
  }
  return refused;
}

/** Transitions 5 (on the way) and 6 (arrived). */
export function advance(b: Booking, to: Status, s: Stamp): Refusal {
  if (to !== Status.OnTheWay && to !== Status.Arrived) {
    return BookingReasons.InvalidTransition;
  }
  return move(b, { to, actor: Actor.Provider }, s);
}

/**
 * Transition 7. A wrong code counts an attempt; the last allowed wrong attempt locks
 * entry for the lockout period. The booking changes even when the code is refused, so
 * callers save it either way.
 */
export function start(b: Booking, code: string, s: Stamp, limits: CodeLimits): Refusal {
  if (b.status !== Status.Arrived) {
    return BookingReasons.InvalidTransition;
  }
  if (b.codeLockedUntil !== null && s.now < b.codeLockedUntil) {
    return BookingReasons.CodeLocked;
  }
  if (code !== b.startCode) {
    b.codeAttempts++;
    if (b.codeAttempts >= limits.maxAttempts) {
      b.codeAttempts = 0;
      b.codeLockedUntil = new Date(s.now.getTime() + limits.lockoutMs);
    }
    return BookingReasons.CodeWrong;
  }
  b.codeAttempts = 0;
  b.codeLockedUntil = null;
  b.startedAt = s.now;
  return move(b, { to: Status.InProgress, actor: Actor.Provider }, s);
}

/** Adds an extras proposal of catalog items (PRD §5: no free-text prices). */
export function propose(b: Booking, p: Proposal): Refusal {
  if (b.status !== Status.InProgress) {
    return BookingReasons.InvalidTransition;
  }
  if (pending(b) !== undefined) {
    return BookingReasons.ExtrasPending;
  }
  if (p.lines.length === 0) {
    return BookingReasons.Invalid;
  }
  p.status = 'pending';
  p.addedPaisa = total(p.lines);
  b.proposals.push(p);
  return undefined;
}

/** Approves or declines the pending proposal; approved items join the bill. */
export function decide(b: Booking, proposalId: string, approve: boolean, now: Date): Refusal {
  const p = pending(b);
  if (b.status !== Status.InProgress || p?.id !== proposalId) {
    return BookingReasons.NoProposal;
  }
  p.status = approve ? 'approved' : 'declined';
  p.decidedAt = now;
  if (approve) {
    b.lines = [...b.lines, ...p.lines.map((l) => ({ ...l, extra: true, proposalId: p.id }))];
    b.totalPaisa = total(b.lines);
  }
  return undefined;
}

/** Transition 8: cash confirmed and no proposal pending (D4). */
export function complete(b: Booking, cash: boolean, s: Stamp): Refusal {
  if (b.status === Status.InProgress && !cash) {
    return BookingReasons.CashNotConfirmed;
  }
  if (b.status === Status.InProgress && pending(b) !== undefined) {
    return BookingReasons.ExtrasPending;
  }
  const refused = move(b, { to: Status.Completed, actor: Actor.Provider }, s);
  if (refused === undefined) {
    b.cashReceived = true;
    b.completedAt = s.now;
  }
  return refused;
}
