import { type Type } from '@nestjs/common';
import { AdminModule } from '../modules/admin/admin.module';
import { AuditModule } from '../modules/audit/audit.module';
import { BookingModule } from '../modules/booking/booking.module';
import { CatalogModule } from '../modules/catalog/catalog.module';
import { CustomerModule } from '../modules/customer/customer.module';
import { IdentityModule } from '../modules/identity/identity.module';
import { MediaModule } from '../modules/media/media.module';
import { NotificationModule } from '../modules/notification/notification.module';
import { ProviderModule } from '../modules/provider/provider.module';
import { RatingModule } from '../modules/rating/rating.module';
import { VerificationModule } from '../modules/verification/verification.module';

/**
 * Every business module, in the order of `migrations/modules.json`. Module agents add
 * their `<Module>Module` here; the API and the worker import the same list.
 */
export const BUSINESS_MODULES: Type[] = [
  IdentityModule,
  CustomerModule,
  ProviderModule,
  VerificationModule,
  CatalogModule,
  BookingModule,
  RatingModule,
  NotificationModule,
  MediaModule,
  AdminModule,
  AuditModule,
];
