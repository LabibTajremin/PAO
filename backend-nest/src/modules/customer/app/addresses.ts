import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import {
  type Address,
  type AddressFields,
  addressProblem,
  MAX_ADDRESSES,
} from '../domain/customer';
import { CUSTOMER_REPOSITORY, type CustomerRepository } from '../port/repository';
import { CustomerReasons } from './errors';

/** An address as the customer types it in. */
export interface AddressInput extends AddressFields {
  readonly isDefault: boolean;
}

function check(a: AddressFields): void {
  const problem = addressProblem(a);
  if (problem === 'invalid') {
    throw new DomainError(CustomerReasons.Invalid);
  }
  if (problem === 'outside_country') {
    throw new DomainError(CustomerReasons.OutsideCountry);
  }
}

/** Saved addresses with map pins (C-02). */
@Injectable()
export class SavedAddresses {
  constructor(
    @Inject(CUSTOMER_REPOSITORY) private readonly repo: CustomerRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** The customer's addresses, default first. */
  list(customerId: string): Promise<Address[]> {
    return this.repo.listAddresses(customerId);
  }

  /** One of the customer's addresses. */
  get(customerId: string, addressId: string): Promise<Address> {
    return this.repo.getAddress(customerId, addressId);
  }

  /** Saves a new address, up to {@link MAX_ADDRESSES}. */
  async add(customerId: string, input: AddressInput): Promise<Address> {
    check(input);
    const id = this.ids.newId();
    return this.repo.addAddress(
      { ...input, id, customerId, createdAt: this.clock.now() },
      MAX_ADDRESSES,
    );
  }

  /** Edits an address. */
  async update(customerId: string, addressId: string, input: AddressInput): Promise<Address> {
    check(input);
    const now = this.clock.now();
    await this.repo.updateAddress({ ...input, id: addressId, customerId, createdAt: now }, now);
    return this.repo.getAddress(customerId, addressId);
  }

  /** Makes an address the default. */
  async setDefault(customerId: string, addressId: string): Promise<Address> {
    await this.repo.setDefault(customerId, addressId);
    return this.repo.getAddress(customerId, addressId);
  }

  /** Removes an address. */
  delete(customerId: string, addressId: string): Promise<void> {
    return this.repo.deleteAddress(customerId, addressId);
  }
}
