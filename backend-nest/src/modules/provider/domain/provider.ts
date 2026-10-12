import { type ProviderReason, ProviderReasons } from './reasons';

/** A WGS84 position in decimal degrees. */
export interface Point {
  readonly lat: number;
  readonly lng: number;
}

/** The guarantor from PRD §6.2 item 6. */
export interface EmergencyContact {
  readonly name: string;
  readonly relation: string;
  readonly phone: string;
  readonly verifiedAt: Date | null;
}

/** The enrolment profile plus read-model copies of level, status and rating. */
export interface Provider {
  readonly id: string;
  readonly phone: string;
  readonly fullName: string;
  readonly dateOfBirth: Date | null;
  readonly gender: string;
  readonly presentAddress: string;
  readonly permanentAddress: string;
  readonly bio: string;
  readonly photoMediaId: string | null;
  readonly experienceYears: number;
  readonly language: string;
  readonly serviceIds: readonly string[];
  readonly homeBase: Point | null;
  readonly workingRadiusM: number;
  readonly emergency: EmergencyContact;
  readonly cocVersion: string;
  readonly cocAcceptedAt: Date | null;
  readonly stepsDone: readonly string[];
  readonly submittedAt: Date | null;
  readonly accountStatus: string;
  readonly level: number;
  readonly ratingAvg: number;
  readonly ratingCount: number;
  readonly completedJobs: number;
  readonly flagged: boolean;
  readonly flagReason: string;
  readonly createdAt: Date;
}

/** No emergency contact yet. */
export const NO_CONTACT: EmergencyContact = { name: '', relation: '', phone: '', verifiedAt: null };

/** A profile nobody has saved anything into: what a fresh enrolment starts from. */
export function emptyProvider(id: string, phone = '', createdAt = new Date(0)): Provider {
  return {
    id,
    phone,
    fullName: '',
    dateOfBirth: null,
    gender: '',
    presentAddress: '',
    permanentAddress: '',
    bio: '',
    photoMediaId: null,
    experienceYears: 0,
    language: 'bn',
    serviceIds: [],
    homeBase: null,
    workingRadiusM: 0,
    emergency: NO_CONTACT,
    cocVersion: '',
    cocAcceptedAt: null,
    stepsDone: [],
    submittedAt: null,
    accountStatus: 'active',
    level: 0,
    ratingAvg: 0,
    ratingCount: 0,
    completedJobs: 0,
    flagged: false,
    flagReason: '',
    createdAt,
  };
}

/**
 * Why presence may not be switched on, or undefined for an active, verified provider
 * with a service area (PRD §6.1).
 */
export function cannotGoOnline(p: Provider): ProviderReason | undefined {
  if (p.accountStatus !== 'active' || p.level < 1) {
    return ProviderReasons.NotVerified;
  }
  if (p.homeBase === null || p.serviceIds.length === 0) {
    return ProviderReasons.NoServiceArea;
  }
  return undefined;
}

/** The customer-facing label of a level (PRD §6.1). */
export function badge(level: number): 'none' | 'verified' | 'verified_pro' {
  if (level >= 2) {
    return 'verified_pro';
  }
  return level === 1 ? 'verified' : 'none';
}
