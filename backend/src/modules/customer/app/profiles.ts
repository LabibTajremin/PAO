import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type CustomerQuery, type CustomerRecord } from '../contract/admin-search';
import { CustomerEvents, type CustomerProfileSaved } from '../contract/events';
import { type Customer, profileProblem } from '../domain/customer';
import { ACCOUNTS, type Accounts, PHOTOS, type Photos } from '../port/peers';
import { CUSTOMER_REPOSITORY, type CustomerRepository } from '../port/repository';
import { CustomerReasons } from './errors';

/** What the customer sees of their own profile. */
export interface Profile extends Customer {
  readonly phone: string;
  /** Empty without a photo. */
  readonly photoUrl: string;
}

/** What a customer may change on their profile. */
export interface ProfileInput {
  readonly name: string;
  readonly language: string;
  readonly photoMediaId: string | null;
}

/** Customer profiles (C-01) and the admin customer list (A-05). */
@Injectable()
export class CustomerProfiles {
  constructor(
    @Inject(CUSTOMER_REPOSITORY) private readonly repo: CustomerRepository,
    @Inject(PHOTOS) private readonly photos: Photos,
    @Inject(ACCOUNTS) private readonly accounts: Accounts,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** The stored profile. */
  customer(id: string): Promise<Customer> {
    return this.repo.getCustomer(id);
  }

  /** The profile with the phone number and a signed photo URL. */
  async profile(id: string): Promise<Profile> {
    const c = await this.repo.getCustomer(id);
    const { phone } = await this.accounts.account(id);
    const photoUrl = c.photoMediaId === null ? '' : await this.photos.url(id, c.photoMediaId);
    return { ...c, phone, photoUrl };
  }

  /** Creates or updates the profile; a photo must be the customer's own confirmed avatar. */
  async save(id: string, input: ProfileInput): Promise<Profile> {
    const name = input.name.trim();
    if (profileProblem(name, input.language) !== null) {
      throw new DomainError(CustomerReasons.Invalid);
    }
    if (input.photoMediaId !== null) {
      await this.photos.attachAvatar(id, input.photoMediaId);
    }
    const { phone, status } = await this.accounts.account(id);
    const saved: CustomerProfileSaved = {
      name: CustomerEvents.CustomerProfileSaved,
      customerId: id,
      customerName: name,
    };
    await this.repo.saveCustomer(
      { ...input, id, name, updatedAt: this.clock.now(), phone, status },
      saved,
    );
    return this.profile(id);
  }

  /** Lists customers for the admin console, newest first. */
  search(q: CustomerQuery): Promise<CustomerRecord[]> {
    return this.repo.search(q);
  }
}
