import { type Point } from '../../../platform/geo/point';
import { type CustomerQuery, type CustomerRecord } from './admin-search';
import { type Address, type Customer } from './dto';

/** What other modules may ask of the customer module (PRD §9.3 rule 1). */
export interface CustomerService {
  /** Returns a customer profile, or throws `CustomerErrors.NotFound`. */
  getCustomer(customerId: string): Promise<Customer>;
  /**
   * Returns one of the customer's saved addresses with its exact location, or throws
   * `CustomerErrors.AddressNotFound`. Callers must only reveal it to a provider after
   * acceptance (PRD §11).
   */
  getAddress(customerId: string, addressId: string): Promise<Address>;
  /** Reports whether a point lies inside an active launch area (C35). */
  isInServiceArea(point: Point): Promise<boolean>;
  /** Lists customers with a profile for the admin console, newest first (A-05). */
  searchCustomers(query: CustomerQuery): Promise<CustomerRecord[]>;
}

/** Injection token for the {@link CustomerService}. */
export const CUSTOMER_SERVICE = Symbol('CustomerService');
