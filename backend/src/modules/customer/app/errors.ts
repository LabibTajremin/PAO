import { CustomerErrors } from '../contract/errors';

/** `DomainError` reasons of the customer module; only `adapter/http` maps them to API errors. */
export const CustomerReasons = {
  ...CustomerErrors,
  /** Name, language or address fields break the rules. */
  Invalid: 'customer.invalid',
  /** The photo is not a confirmed avatar upload of this customer. */
  InvalidPhoto: 'customer.invalid_photo',
  /** The pin lies outside Bangladesh. */
  OutsideCountry: 'customer.outside_country',
  /** The customer already has the maximum number of addresses. */
  AddressLimit: 'customer.address_limit',
  /** Addresses need a profile first. */
  ProfileRequired: 'customer.profile_required',
} as const;
