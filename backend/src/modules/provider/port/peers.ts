import { type Text } from '../../../platform/i18n/text';

/** The catalog's view of a service. */
export interface Service {
  readonly id: string;
  readonly name: Text;
  readonly published: boolean;
  readonly minLevel: number;
  readonly womenProvidersOnly: boolean;
}

/** Reads services; an unknown one throws `provider.unknown_service`. */
export interface Catalog {
  service(id: string): Promise<Service>;
}

/** Reaches identity: the phone number and one-time codes for the emergency contact. */
export interface Accounts {
  phone(id: string): Promise<string>;
  sendContactCode(phone: string): Promise<void>;
  checkContactCode(phone: string, code: string): Promise<void>;
}

/** Checks and shows the profile photo. */
export interface Media {
  /** Throws `provider.invalid_photo` unless it is the owner's confirmed avatar. */
  attachAvatar(owner: string, id: string): Promise<void>;
  url(viewer: string, id: string): Promise<string>;
}

/** The review thresholds from the admin settings (D13). */
export interface Quality {
  readonly ratingFloor: number;
  readonly ratingMinJobs: number;
  readonly maxCancellations: number;
}

/** Reads the quality thresholds. */
export interface Settings {
  quality(): Promise<Quality>;
}

/** A provider's rating breakdown. */
export interface Rating {
  readonly average: number;
  readonly count: number;
  readonly distribution: readonly number[];
}

/** Reads provider ratings. */
export interface Ratings {
  providerRating(id: string): Promise<Rating>;
}

/** Injection token for the {@link Catalog}. */
export const CATALOG = Symbol('ProviderCatalog');
/** Injection token for the {@link Accounts}. */
export const ACCOUNTS = Symbol('ProviderAccounts');
/** Injection token for the {@link Media}. */
export const MEDIA = Symbol('ProviderMedia');
/** Injection token for the {@link Settings}. */
export const SETTINGS = Symbol('ProviderSettings');
/** Injection token for the {@link Ratings}. */
export const RATINGS = Symbol('ProviderRatings');
