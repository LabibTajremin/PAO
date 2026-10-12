import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { AUDIT_SERVICE, type AuditService } from '../../../audit/contract/audit-service';
import { BOOKING_SERVICE, type BookingService } from '../../../booking/contract/booking-service';
import { CATALOG_SERVICE, type CatalogService } from '../../../catalog/contract/catalog-service';
import {
  CUSTOMER_SERVICE,
  type CustomerService,
} from '../../../customer/contract/customer-service';
import {
  IDENTITY_SERVICE,
  type IdentityService,
} from '../../../identity/contract/identity-service';
import {
  PROVIDER_SERVICE,
  type ProviderService,
} from '../../../provider/contract/provider-service';
import { RATING_SERVICE, type RatingService } from '../../../rating/contract/rating-service';
import {
  VERIFICATION_SERVICE,
  type VerificationService,
} from '../../../verification/contract/verification-service';
import { type Console } from '../../port/console';

/** The owners' contracts, resolved on first use (the Go module's `admin.Late`). */
@Injectable()
export class LazyConsole implements Console {
  private readonly contracts: {
    providers: LazyContract<ProviderService>;
    customers: LazyContract<CustomerService>;
    verification: LazyContract<VerificationService>;
    bookings: LazyContract<BookingService>;
    ratings: LazyContract<RatingService>;
    identity: LazyContract<IdentityService>;
    audit: LazyContract<AuditService>;
    catalog: LazyContract<CatalogService>;
  };

  constructor(ref: ModuleRef) {
    this.contracts = {
      providers: new LazyContract(ref, PROVIDER_SERVICE),
      customers: new LazyContract(ref, CUSTOMER_SERVICE),
      verification: new LazyContract(ref, VERIFICATION_SERVICE),
      bookings: new LazyContract(ref, BOOKING_SERVICE),
      ratings: new LazyContract(ref, RATING_SERVICE),
      identity: new LazyContract(ref, IDENTITY_SERVICE),
      audit: new LazyContract(ref, AUDIT_SERVICE),
      catalog: new LazyContract(ref, CATALOG_SERVICE),
    };
  }

  providers(): ProviderService {
    return this.contracts.providers.get();
  }

  customers(): CustomerService {
    return this.contracts.customers.get();
  }

  verification(): VerificationService {
    return this.contracts.verification.get();
  }

  bookings(): BookingService {
    return this.contracts.bookings.get();
  }

  ratings(): RatingService {
    return this.contracts.ratings.get();
  }

  identity(): IdentityService {
    return this.contracts.identity.get();
  }

  audit(): AuditService {
    return this.contracts.audit.get();
  }

  catalog(): CatalogService {
    return this.contracts.catalog.get();
  }
}
