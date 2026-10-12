import { type Type } from '@nestjs/common';
import { AdminModule } from '../modules/admin/admin.module';
import { AuditModule } from '../modules/audit/audit.module';
import { CatalogModule } from '../modules/catalog/catalog.module';
import { CustomerModule } from '../modules/customer/customer.module';
import { IdentityModule } from '../modules/identity/identity.module';
import { MediaModule } from '../modules/media/media.module';

/**
 * Every business module, in the order of `migrations/modules.json`. Module agents add
 * their `<Module>Module` here; the API and the worker import the same list.
 */
export const BUSINESS_MODULES: Type[] = [
  IdentityModule,
  CustomerModule,
  CatalogModule,
  MediaModule,
  AdminModule,
  AuditModule,
];
