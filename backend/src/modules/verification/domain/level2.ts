import { type VerificationReason, VerificationReasons } from './reasons';

/** One line of a Level 2 checklist. */
export interface CheckItem {
  readonly item: string;
  readonly passed: boolean;
}

/** A Level 2 interview, skill test or supervised job (PRD §6.3). */
export interface Session {
  readonly id: string;
  readonly providerId: string;
  readonly serviceId: string;
  readonly scheduledAt: Date;
  readonly location: string;
  readonly status: string;
  readonly result: string;
  readonly checklist: readonly CheckItem[];
  readonly notes: string;
  readonly visitLat: number | null;
  readonly visitLng: number | null;
  readonly photos: readonly string[];
  readonly decidedBy: string | null;
  readonly decidedAt: Date | null;
  readonly createdAt: Date;
}

/** A recorded Level 2 result. */
export interface Outcome {
  readonly result: string;
  readonly checklist: readonly CheckItem[];
  readonly notes: string;
  readonly visitLat: number | null;
  readonly visitLng: number | null;
  readonly photos: readonly string[];
}

/** The session closed with a result, or why it cannot be. */
export function recorded(
  s: Session,
  now: Date,
  actor: string,
  o: Outcome,
): Session | VerificationReason {
  if (s.status !== 'scheduled') {
    return VerificationReasons.SessionClosed;
  }
  if (!['pass', 'fail', 'retest'].includes(o.result)) {
    return VerificationReasons.Invalid;
  }
  return { ...s, ...o, status: 'completed', decidedBy: actor, decidedAt: now };
}

/**
 * The end of the cooling-off period after the latest failed session, or null when the
 * provider may book a session now.
 */
export function retryAfter(
  sessions: readonly Session[],
  coolingOffMs: number,
  now: Date,
): Date | null {
  let last: Date | null = null;
  for (const s of sessions) {
    if (s.result === 'fail' && s.decidedAt !== null && (last === null || s.decidedAt > last)) {
      last = s.decidedAt;
    }
  }
  if (last === null) {
    return null;
  }
  const until = new Date(last.getTime() + coolingOffMs);
  return until > now ? until : null;
}
