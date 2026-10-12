/**
 * `DomainError` reasons the customer module raises through its contract; other modules
 * compare against these with `isDomainError`.
 */
export const CustomerErrors = {
  /** No customer profile has the id. */
  NotFound: 'customer.not_found',
  /** The customer has no saved address with the id. */
  AddressNotFound: 'customer.address_not_found',
} as const;

/** A reason from {@link CustomerErrors}. */
export type CustomerErrorReason = (typeof CustomerErrors)[keyof typeof CustomerErrors];
