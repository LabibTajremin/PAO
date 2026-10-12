import { Controller, Get, Inject, Param, Query } from '@nestjs/common';
import { type components } from '../../../../platform/http/openapi.gen';
import { MapErrors } from '../../../../platform/http/map-errors';
import { RequirePermission } from '../../../../platform/http/permissions';
import { BrowseCatalog } from '../../app/browse-catalog';
import { CatalogTree } from '../../app/catalog-tree';
import { catalogErrors } from './errors';
import { serviceView, subServiceView, treeView } from './views';

type Schemas = components['schemas'];

/** Browsing and search for the customer app (C-03, C08, C09). */
@Controller('v1/customer')
@MapErrors(catalogErrors)
@RequirePermission('catalog:read')
export class CustomerCatalogController {
  constructor(
    @Inject(CatalogTree) private readonly tree: CatalogTree,
    @Inject(BrowseCatalog) private readonly browse: BrowseCatalog,
  ) {}

  @Get('catalog')
  async catalog(): Promise<Schemas['CatalogTree']> {
    return treeView(await this.tree.published());
  }

  @Get('catalog/search')
  async search(@Query('q') q: string): Promise<Schemas['CatalogSearchResults']> {
    const found = await this.browse.search(q);
    return {
      services: found.services.map(serviceView),
      subServices: found.subServices.map(subServiceView),
    };
  }

  @Get('services/:serviceId')
  async service(@Param('serviceId') id: string): Promise<Schemas['Service']> {
    return serviceView(await this.browse.publishedService(id));
  }
}

/** The published catalog for the provider app, e.g. to pick services at enrolment. */
@Controller('v1/provider/catalog')
@MapErrors(catalogErrors)
@RequirePermission('catalog:read')
export class ProviderCatalogController {
  constructor(@Inject(CatalogTree) private readonly tree: CatalogTree) {}

  @Get()
  async catalog(): Promise<Schemas['CatalogTree']> {
    return treeView(await this.tree.published());
  }
}
