import { Global, Module } from '@nestjs/common';
import { Cache } from '../../platform/redis/cache';
import { CATALOG_SEEDER } from '../../platform/seeding/seeders';
import { AdminCatalogController } from './adapter/http/admin-catalog.controller';
import {
  CustomerCatalogController,
  ProviderCatalogController,
} from './adapter/http/catalog.controller';
import { InprocCatalogService } from './adapter/inproc/catalog-service';
import { PostgresCatalogRepository } from './adapter/postgres/catalog-repository';
import { BrowseCatalog } from './app/browse-catalog';
import { CatalogTree } from './app/catalog-tree';
import { ChangePrice } from './app/change-price';
import { EditCatalog } from './app/edit-catalog';
import { SeedCatalog } from './app/seed-catalog';
import { CATALOG_SERVICE } from './contract/catalog-service';
import { CATALOG_REPOSITORY, TREE_CACHE } from './port/catalog-repository';

/** Categories, services, sub-services and versioned prices (PRD §4). */
@Global()
@Module({
  controllers: [CustomerCatalogController, ProviderCatalogController, AdminCatalogController],
  providers: [
    { provide: CATALOG_REPOSITORY, useClass: PostgresCatalogRepository },
    { provide: TREE_CACHE, useExisting: Cache },
    CatalogTree,
    BrowseCatalog,
    EditCatalog,
    ChangePrice,
    { provide: CATALOG_SEEDER, useClass: SeedCatalog },
    { provide: CATALOG_SERVICE, useClass: InprocCatalogService },
  ],
  exports: [CATALOG_SERVICE, CATALOG_SEEDER],
})
export class CatalogModule {}
