import { type DomainEvent } from '../../../platform/events/domain-event';
import { type CustomerQuery, type CustomerRecord } from '../contract/admin-search';
import { type Address, type Customer } from '../domain/customer';

/** A profile as stored, with the identity copies the admin list shows (A-05). */
export interface StoredCustomer extends Customer {
  readonly phone: string;
  readonly status: string;
}

/**
 * Stores profiles and addresses. Address writes that touch the default flag or the
 * per-customer limit run in one transaction holding the customer's row lock.
 */
export interface CustomerRepository {
  saveCustomer(c: StoredCustomer, event: DomainEvent): Promise<void>;
  /** Throws `customer.not_found`. */
  getCustomer(id: string): Promise<Customer>;
  search(q: CustomerQuery): Promise<CustomerRecord[]>;
  /** Inserts `a`, making it the default when asked or when it is the first. */
  addAddress(a: Address, limit: number): Promise<Address>;
  /** Edits `a`; a true `isDefault` makes it the default, false leaves the default alone. */
  updateAddress(a: Address, updatedAt: Date): Promise<void>;
  setDefault(customerId: string, addressId: string): Promise<void>;
  /** Removes an address; deleting the default promotes the newest one left. */
  deleteAddress(customerId: string, addressId: string): Promise<void>;
  /** Lists addresses, default first, then newest. */
  listAddresses(customerId: string): Promise<Address[]>;
  /** Throws `customer.address_not_found`. */
  getAddress(customerId: string, addressId: string): Promise<Address>;
}

/** Injection token for the {@link CustomerRepository}. */
export const CUSTOMER_REPOSITORY = Symbol('CustomerRepository');
