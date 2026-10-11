import { type Type } from '@nestjs/common';
import { AdminModule } from '../modules/admin/admin.module';
import { IdentityModule } from '../modules/identity/identity.module';

/**
 * Every business module, in the order of `migrations/modules.json`. Module agents add
 * their `<Module>Module` here, one per line; the API and the worker import the same list.
 */
export const BUSINESS_MODULES: Type[] = [IdentityModule, AdminModule];
