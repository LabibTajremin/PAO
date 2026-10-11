import { type Text } from '../../../platform/i18n/text';

/** How a service books (PRD §4). */
export const ServiceModel = {
  OnDemand: 'on_demand',
  DurationHire: 'duration_hire',
  Listing: 'listing',
  PartnerReferral: 'partner_referral',
} as const;

/** How a service books (PRD §4). */
export type ServiceModel = (typeof ServiceModel)[keyof typeof ServiceModel];

/** What one quantity of a sub-service means. */
export const PriceUnit = {
  Job: 'job',
  Unit: 'unit',
  Hour: 'hour',
  Day: 'day',
} as const;

/** What one quantity of a sub-service means. */
export type PriceUnit = (typeof PriceUnit)[keyof typeof PriceUnit];

/** A trade within a category, with the rules other modules enforce. */
export interface Service {
  readonly id: string;
  readonly categoryId: string;
  readonly name: Text;
  readonly model: ServiceModel;
  readonly requiredLevel: number;
  readonly searchRadiusM: number;
  readonly womenProvidersOnly: boolean;
  readonly requiresLevel2: boolean;
  readonly level2Checklist: readonly Text[];
  readonly published: boolean;
}

/** The price of one sub-service at a moment, copied onto bookings. */
export interface PriceSnapshot {
  readonly subServiceId: string;
  readonly serviceId: string;
  readonly priceVersionId: string;
  readonly name: Text;
  readonly unit: PriceUnit;
  readonly amountPaisa: number;
  readonly maxQuantity: number;
  readonly published: boolean;
}
