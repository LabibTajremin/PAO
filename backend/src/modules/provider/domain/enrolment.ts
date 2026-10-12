import { type EmergencyContact, type Point } from './provider';
import { type ProviderReason, ProviderReasons } from './reasons';

/** The enrolment wizard in order (M05–M13). */
export const STEPS = [
  'personal',
  'services',
  'area',
  'nid',
  'selfie',
  'police_clearance',
  'skill_proof',
  'emergency_contact',
  'code_of_conduct',
] as const;

/** One step's progress. */
export interface StepStatus {
  readonly step: string;
  readonly done: boolean;
  readonly required: boolean;
}

/** The wizard state. */
export interface Progress {
  readonly steps: StepStatus[];
  readonly complete: boolean;
  readonly submitted: boolean;
}

/**
 * Every step's status and whether all required ones are done. Skill proof is optional
 * for Level 1 (PRD §6.2 item 7).
 */
export function progress(done: readonly string[], submitted = false): Progress {
  const steps = STEPS.map((step) => ({
    step,
    done: done.includes(step),
    required: step !== 'skill_proof',
  }));
  const complete = steps.every((s) => s.done || !s.required);
  return { steps, complete, submitted };
}

/** Adds a step to the done list once. */
export function withStep(done: readonly string[], step: string): string[] {
  return done.includes(step) ? [...done] : [...done, step];
}

/** Removes a step from the done list. */
export function withoutStep(done: readonly string[], step: string): string[] {
  return done.filter((s) => s !== step);
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

/** Counts characters as Go counted runes. */
export function length(s: string): number {
  return Array.from(s).length;
}

function between(s: string, lo: number, hi: number): boolean {
  const n = length(s.trim());
  return n >= lo && n <= hi;
}

/** The M05 fields. */
export interface Personal {
  readonly fullName: string;
  readonly dateOfBirth: Date;
  readonly gender: string;
  readonly presentAddress: string;
  readonly permanentAddress: string;
  readonly bio: string;
}

function eighteenthBirthday(born: Date): Date {
  const d = new Date(born);
  d.setUTCFullYear(d.getUTCFullYear() + 18);
  return d;
}

/** Checks the personal step; the provider must be 18 on `today`. */
export function personalProblem(p: Personal, today: Date): ProviderReason | undefined {
  const fits =
    between(p.fullName, 3, 100) &&
    between(p.presentAddress, 5, 300) &&
    between(p.permanentAddress, 5, 300) &&
    length(p.bio) <= 500 &&
    ['female', 'male', 'other'].includes(p.gender);
  if (!fits) {
    return ProviderReasons.Invalid;
  }
  return eighteenthBirthday(p.dateOfBirth) > today ? ProviderReasons.TooYoung : undefined;
}

/** The M06 step: one to five services and plausible experience. */
export function servicesValid(count: number, experienceYears: number): boolean {
  return count >= 1 && count <= 5 && experienceYears >= 0 && experienceYears <= 60;
}

/** The M07 step: a home base in Bangladesh and a 1–30 km radius. */
export function areaValid(p: Point, radiusM: number): boolean {
  const inBangladesh = p.lat >= 20.5 && p.lat <= 26.7 && p.lng >= 88.0 && p.lng <= 92.7;
  return inBangladesh && radiusM >= 1000 && radiusM <= 30000;
}

/** The emergency contact must be someone else's phone. */
export function contactValid(c: EmergencyContact, ownPhone: string): boolean {
  return (
    between(c.name, 2, 80) && between(c.relation, 2, 40) && c.phone !== '' && c.phone !== ownPhone
  );
}

/**
 * A Bangladeshi mobile number as +8801XXXXXXXXX, or undefined; the API accepts the local
 * and international spellings.
 */
export function normalizePhone(raw: string): string | undefined {
  let s = raw.startsWith('+') ? raw.slice(1) : raw;
  s = s.startsWith('880') ? s.slice(3) : s;
  s = s.startsWith('0') ? s.slice(1) : s;
  return /^1[3-9][0-9]{8}$/.test(s) ? `+880${s}` : undefined;
}
