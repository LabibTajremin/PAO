import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { randomDigits } from '../../../../platform/auth/random';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { ADMIN_SERVICE, type AdminService } from '../../../admin/contract/admin-service';
import { CATALOG_SERVICE, type CatalogService } from '../../../catalog/contract/catalog-service';
import { CatalogErrors } from '../../../catalog/contract/errors';
import {
  CUSTOMER_SERVICE,
  type CustomerService,
} from '../../../customer/contract/customer-service';
import { CustomerErrors } from '../../../customer/contract/errors';
import {
  IDENTITY_SERVICE,
  type IdentityService,
} from '../../../identity/contract/identity-service';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { ProviderErrors } from '../../../provider/contract/errors';
import {
  PROVIDER_SERVICE,
  type ProviderService,
} from '../../../provider/contract/provider-service';
import { RATING_SERVICE, type RatingService } from '../../../rating/contract/rating-service';
import {
  VERIFICATION_SERVICE,
  type VerificationService,
} from '../../../verification/contract/verification-service';
import { type Address, type Point } from '../../domain/booking';
import { type BookingReason, BookingReasons } from '../../domain/reasons';
import * as port from '../../port/peers';

// Contracts are resolved on first use, so booking starts whichever peers are wired and
// never forms a construction cycle with the modules that read bookings.

/** Rethrows `reason` in place of the contract error `from`. */
function translate(from: string, reason: BookingReason) {
  return (err: unknown): never => {
    throw isDomainError(err, from) ? new DomainError(reason, { cause: err }) : err;
  };
}

/** Reads services and prices through the catalog contract. */
@Injectable()
export class CatalogPrices implements port.Catalog {
  private readonly catalog: LazyContract<CatalogService>;

  constructor(ref: ModuleRef) {
    this.catalog = new LazyContract(ref, CATALOG_SERVICE);
  }

  async service(id: string): Promise<port.Service> {
    const s = await this.catalog
      .get()
      .getService(id)
      .catch(translate(CatalogErrors.ServiceNotFound, BookingReasons.NotFound));
    const { name, model, searchRadiusM, womenProvidersOnly, published } = s;
    return { id: s.id, name, model, searchRadiusM, womenProvidersOnly, published };
  }

  price(subServiceId: string): Promise<port.Price> {
    return this.catalog
      .get()
      .getPriceSnapshot(subServiceId)
      .catch(translate(CatalogErrors.SubServiceNotFound, BookingReasons.Invalid));
  }
}

/** Reads customers through the customer and identity contracts. */
@Injectable()
export class CustomerProfiles implements port.Customers {
  private readonly customers: LazyContract<CustomerService>;
  private readonly identity: LazyContract<IdentityService>;

  constructor(ref: ModuleRef) {
    this.customers = new LazyContract(ref, CUSTOMER_SERVICE);
    this.identity = new LazyContract(ref, IDENTITY_SERVICE);
  }

  /** A booking needs the customer's profile name. */
  async customer(id: string, addressId: string): Promise<port.Customer> {
    const c = await this.customers
      .get()
      .getCustomer(id)
      .catch(translate(CustomerErrors.NotFound, BookingReasons.ProfileRequired));
    const account = await this.identity.get().getAccount(id);
    return { name: c.name, phone: account.phone, address: await this.address(id, addressId) };
  }

  /** Another customer's address is not found. */
  async address(id: string, addressId: string): Promise<Address> {
    const a = await this.customers
      .get()
      .getAddress(id, addressId)
      .catch(translate(CustomerErrors.AddressNotFound, BookingReasons.Invalid));
    const { area, line1, line2, location } = a;
    return { id: a.id, area, line1, line2, location };
  }

  covered(p: Point): Promise<boolean> {
    return this.customers.get().isInServiceArea(p);
  }
}

/** Checks providers through the provider and verification contracts, and finds them. */
@Injectable()
export class ProviderDirectory implements port.Providers, port.Finder {
  private readonly providers: LazyContract<ProviderService>;
  private readonly verification: LazyContract<VerificationService>;

  constructor(ref: ModuleRef) {
    this.providers = new LazyContract(ref, PROVIDER_SERVICE);
    this.verification = new LazyContract(ref, VERIFICATION_SERVICE);
  }

  async provider(id: string): Promise<port.Provider> {
    const p = await this.providers
      .get()
      .getProvider(id)
      .catch(translate(ProviderErrors.NotFound, BookingReasons.NotBookable));
    return { name: p.fullName, phone: p.phone, serviceIds: p.serviceIds };
  }

  isAvailable(id: string): Promise<boolean> {
    return this.providers.get().isAvailable(id);
  }

  canReceiveBookings(id: string, serviceId: string): Promise<boolean> {
    return this.verification.get().canReceiveBookings(id, serviceId);
  }

  async findNearby(q: port.NearbySearch): Promise<port.Nearby[]> {
    const found = await this.providers.get().findNearby({
      serviceId: q.serviceId,
      point: q.at,
      radiusM: q.radiusM,
      womenProvidersOnly: q.womenOnly,
      sort: q.byRating ? 'rating' : 'distance',
      limit: q.limit,
    });
    return found.map(({ providerId, ...card }) => ({ id: providerId, ...card }));
  }
}

/** Signs profile photos through the media contract. */
@Injectable()
export class MediaPhotos implements port.Media {
  private readonly media: LazyContract<MediaService>;

  constructor(ref: ModuleRef) {
    this.media = new LazyContract(ref, MEDIA_SERVICE);
  }

  async url(viewerId: string, mediaId: string): Promise<string> {
    const v = await this.media.get().getViewUrl({ mediaId, viewerId, viewerRole: 'customer' });
    return v.url;
  }
}

/** Reads the booking rules through the admin contract. */
@Injectable()
export class AdminRules implements port.Settings {
  private readonly admin: LazyContract<AdminService>;

  constructor(ref: ModuleRef) {
    this.admin = new LazyContract(ref, ADMIN_SERVICE);
  }

  async rules(): Promise<port.Rules> {
    const s = await this.admin.get().getSettings();
    return {
      acceptAsapMs: s.acceptTimeoutAsapMs,
      acceptScheduledMs: s.acceptTimeoutScheduledMs,
      startCodeMaxAttempts: s.startCodeMaxAttempts,
      startCodeLockoutMs: s.startCodeLockoutMs,
    };
  }
}

/** Asks the rating contract whether a party already reviewed a booking. */
@Injectable()
export class RatingReviews implements port.Reviews {
  private readonly rating: LazyContract<RatingService>;

  constructor(ref: ModuleRef) {
    this.rating = new LazyContract(ref, RATING_SERVICE);
  }

  hasReviewed(bookingId: string, authorId: string): Promise<boolean> {
    return this.rating.get().hasReviewed(bookingId, authorId);
  }
}

/** Start codes from the CSPRNG. */
export class RandomStartCodes implements port.StartCodes {
  next(): string {
    return randomDigits(4);
  }
}
