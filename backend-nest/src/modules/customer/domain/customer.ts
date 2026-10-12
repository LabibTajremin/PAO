/** A WGS84 position in decimal degrees. */
export interface Point {
  readonly lat: number;
  readonly lng: number;
}

/** Saved addresses per customer (C-02). */
export const MAX_ADDRESSES = 10;

/** A customer profile. */
export interface Customer {
  readonly id: string;
  readonly name: string;
  readonly photoMediaId: string | null;
  readonly language: string;
  readonly updatedAt: Date;
}

/** Address labels the app offers. */
export const ADDRESS_LABELS: readonly string[] = ['home', 'office', 'other'];

/** The fields a customer types in for an address. */
export interface AddressFields {
  readonly label: string;
  readonly line1: string;
  readonly line2: string;
  readonly area: string;
  readonly location: Point;
}

/** A saved place with a map pin. */
export interface Address extends AddressFields {
  readonly id: string;
  readonly customerId: string;
  readonly isDefault: boolean;
  readonly createdAt: Date;
}

/** Why a profile or address is refused. */
export type Problem = 'invalid' | 'outside_country';

// Counted in code points, like Go's rune count, so Bangla text gets the same limits.
const length = (s: string): number => Array.from(s).length;

/** Checks the profile fields; null when they are fine. */
export function profileProblem(name: string, language: string): Problem | null {
  const n = length(name.trim());
  return n < 2 || n > 80 || (language !== 'en' && language !== 'bn') ? 'invalid' : null;
}

/** Checks the address fields and that the pin lies in Bangladesh; null when fine. */
export function addressProblem(a: AddressFields): Problem | null {
  const line1 = length(a.line1.trim());
  if (!ADDRESS_LABELS.includes(a.label) || line1 < 3 || line1 > 200) {
    return 'invalid';
  }
  if (length(a.line2) > 200 || length(a.area) > 80) {
    return 'invalid';
  }
  return inBangladesh(a.location) ? null : 'outside_country';
}

/**
 * A bounding-box check: it rejects pins dropped far away (a wrong sign or swapped
 * coordinates) without needing the exact border.
 */
export function inBangladesh(p: Point): boolean {
  return p.lat >= 20.5 && p.lat <= 26.7 && p.lng >= 88.0 && p.lng <= 92.7;
}
