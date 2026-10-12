import { type Point } from '../../../platform/geo/point';
import { type Language } from '../../../platform/i18n/text';

/** The profile a customer sets up after signing in (C-01). */
export interface Customer {
  readonly id: string;
  readonly name: string;
  readonly photoMediaId: string | null;
  readonly language: Language;
}

/** A saved place with a map pin (C-02). */
export interface Address {
  readonly id: string;
  readonly customerId: string;
  readonly label: string;
  readonly line1: string;
  readonly line2: string;
  readonly area: string;
  readonly location: Point;
}
