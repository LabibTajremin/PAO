import { type Point } from '../../../platform/geo/point';
import { type Language } from '../../../platform/i18n/text';

/** Genders recorded during enrolment; home salon uses them (D11). */
export const Gender = {
  Female: 'female',
  Male: 'male',
  Other: 'other',
} as const;

/** A gender recorded during enrolment (D11). */
export type Gender = (typeof Gender)[keyof typeof Gender];

/** The guarantor from PRD §6.2 item 6. */
export interface EmergencyContact {
  readonly name: string;
  readonly relation: string;
  readonly phone: string;
  readonly verifiedAt: Date | null;
}

/** The enrolment profile other modules read. */
export interface Provider {
  readonly id: string;
  readonly fullName: string;
  readonly dateOfBirth: Date | null;
  readonly gender: Gender;
  readonly presentAddress: string;
  readonly permanentAddress: string;
  readonly phone: string;
  readonly photoMediaId: string | null;
  readonly serviceIds: readonly string[];
  readonly experienceYears: number;
  readonly homeBase: Point | null;
  readonly workingRadiusM: number;
  readonly language: Language;
  readonly emergencyContact: EmergencyContact | null;
  readonly submittedAt: Date | null;
}

/** Orders of the nearby list after the Level 2 ranking. */
export const SortOrder = {
  Distance: 'distance',
  Rating: 'rating',
} as const;

/** Orders the nearby list after the Level 2 ranking. */
export type SortOrder = (typeof SortOrder)[keyof typeof SortOrder];

/** Asks for providers around a point. */
export interface NearbyQuery {
  readonly serviceId: string;
  readonly point: Point;
  readonly radiusM: number;
  readonly womenProvidersOnly: boolean;
  readonly sort: SortOrder;
  readonly limit: number;
}

/** One search result. */
export interface NearbyProvider {
  readonly providerId: string;
  readonly name: string;
  readonly photoMediaId: string | null;
  readonly level: number;
  readonly rating: number;
  readonly ratingCount: number;
  readonly completedJobs: number;
  readonly distanceM: number;
}
