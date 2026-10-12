import { type AuditService } from '../../audit/contract/audit-service';
import { type BookingService } from '../../booking/contract/booking-service';
import { type CatalogService } from '../../catalog/contract/catalog-service';
import { type CustomerService } from '../../customer/contract/customer-service';
import { type IdentityService } from '../../identity/contract/identity-service';
import { type ProviderService } from '../../provider/contract/provider-service';
import { type RatingService } from '../../rating/contract/rating-service';
import { type VerificationService } from '../../verification/contract/verification-service';

/**
 * The modules that own what the admin console shows (ADR-0026). Each is fetched when
 * used, because several of them read admin settings themselves.
 */
export interface Console {
  providers(): ProviderService;
  customers(): CustomerService;
  verification(): VerificationService;
  bookings(): BookingService;
  ratings(): RatingService;
  identity(): IdentityService;
  audit(): AuditService;
  catalog(): CatalogService;
}

/** Injection token for the {@link Console}. */
export const CONSOLE = Symbol('AdminConsole');

/** Keeps one rebuildable value, e.g. the settings or the dashboard; never fails. */
export interface CachedValue<T> {
  read(): Promise<T | undefined>;
  write(value: T): Promise<void>;
  invalidate(): Promise<void>;
}
