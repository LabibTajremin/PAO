import { type Type } from '@nestjs/common';
import { CatalogModule } from '../modules/catalog/catalog.module';
import { MediaModule } from '../modules/media/media.module';

/**
 * Every business module, in the order of `migrations/modules.json`. Module agents add
 * their `<Module>Module` here; the API and the worker import the same list.
 */
export const BUSINESS_MODULES: Type[] = [CatalogModule, MediaModule];
