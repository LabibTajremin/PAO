import { type Address, type Point, type Text } from '../domain/booking';

/** A sub-service's current price version. */
export interface Price {
  readonly subServiceId: string;
  readonly serviceId: string;
  readonly priceVersionId: string;
  readonly name: Text;
  readonly unit: string;
  readonly amountPaisa: number;
  readonly maxQuantity: number;
  readonly published: boolean;
}

/** The catalog's view of a bookable service. */
export interface Service {
  readonly id: string;
  readonly name: Text;
  readonly model: string;
  readonly searchRadiusM: number;
  readonly womenProvidersOnly: boolean;
  readonly published: boolean;
}

/**
 * Reads services and prices; an unknown service throws `booking.not_found` and an
 * unknown sub-service `booking.invalid`.
 */
export interface Catalog {
  service(id: string): Promise<Service>;
  price(subServiceId: string): Promise<Price>;
}

/** The booking-side view of a customer. */
export interface Customer {
  readonly name: string;
  readonly phone: string;
  readonly address: Address;
}

/** Reads the customer's profile, phone and saved addresses. */
export interface Customers {
  /** Throws `booking.profile_required` without a profile. */
  customer(id: string, addressId: string): Promise<Customer>;
  /** Throws `booking.invalid` for another customer's or an unknown address. */
  address(id: string, addressId: string): Promise<Address>;
  /** Reports whether the point is inside the launch area (D5). */
  covered(p: Point): Promise<boolean>;
}

/** The booking-side view of a provider. */
export interface Provider {
  readonly name: string;
  readonly phone: string;
  readonly serviceIds: readonly string[];
}

/** Checks availability and eligibility. */
export interface Providers {
  /** Throws `booking.not_bookable` for an unknown provider. */
  provider(id: string): Promise<Provider>;
  isAvailable(id: string): Promise<boolean>;
  canReceiveBookings(id: string, serviceId: string): Promise<boolean>;
}

/** A provider found for a customer. */
export interface Nearby {
  readonly id: string;
  readonly name: string;
  readonly photoMediaId: string | null;
  readonly level: number;
  readonly rating: number;
  readonly ratingCount: number;
  readonly completedJobs: number;
  readonly distanceM: number;
}

/** What a nearby search asks for. */
export interface NearbySearch {
  readonly serviceId: string;
  readonly at: Point;
  readonly radiusM: number;
  readonly womenOnly: boolean;
  readonly byRating: boolean;
  readonly limit: number;
}

/** Searches online providers. */
export interface Finder {
  findNearby(q: NearbySearch): Promise<Nearby[]>;
}

/** Shows profile photos. */
export interface Media {
  url(viewerId: string, mediaId: string): Promise<string>;
}

/** The admin-editable booking settings (D12). */
export interface Rules {
  readonly acceptAsapMs: number;
  readonly acceptScheduledMs: number;
  readonly startCodeMaxAttempts: number;
  readonly startCodeLockoutMs: number;
}

/** Reads the rules. */
export interface Settings {
  rules(): Promise<Rules>;
}

/** Tells whether a party already reviewed a completed booking. */
export interface Reviews {
  hasReviewed(bookingId: string, authorId: string): Promise<boolean>;
}

/** Makes fresh 4-digit start codes from a CSPRNG. */
export interface StartCodes {
  next(): string;
}

/** Injection token for the {@link Catalog}. */
export const CATALOG = Symbol('BookingCatalog');
/** Injection token for the {@link Customers}. */
export const CUSTOMERS = Symbol('BookingCustomers');
/** Injection token for the {@link Providers}. */
export const PROVIDERS = Symbol('BookingProviders');
/** Injection token for the {@link Finder}. */
export const FINDER = Symbol('BookingFinder');
/** Injection token for the {@link Media}. */
export const MEDIA = Symbol('BookingMedia');
/** Injection token for the {@link Settings}. */
export const SETTINGS = Symbol('BookingSettings');
/** Injection token for the {@link Reviews}. */
export const REVIEWS = Symbol('BookingReviews');
/** Injection token for the {@link StartCodes}. */
export const START_CODES = Symbol('BookingStartCodes');
