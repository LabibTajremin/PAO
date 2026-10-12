import { Body, Controller, Get, HttpCode, Inject, Param, Post, Put } from '@nestjs/common';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type components } from '../../../../platform/http/openapi.gen';
import { MapErrors } from '../../../../platform/http/map-errors';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { CatalogTree } from '../../app/catalog-tree';
import { ChangePrice } from '../../app/change-price';
import { EditCatalog } from '../../app/edit-catalog';
import { CatalogReason } from '../../domain/errors';
import { catalogErrors } from './errors';
import {
  categoryInput,
  categoryView,
  priceView,
  serviceInput,
  serviceView,
  subServiceInput,
  subServiceView,
  treeView,
} from './views';

type Schemas = components['schemas'];

/** Catalog and price management for admins (A-02, A03). */
@Controller('v1/admin/catalog')
@MapErrors(catalogErrors)
@RequirePermission('catalog:manage')
export class AdminCatalogController {
  constructor(
    @Inject(CatalogTree) private readonly tree: CatalogTree,
    @Inject(EditCatalog) private readonly edit: EditCatalog,
    @Inject(ChangePrice) private readonly prices: ChangePrice,
  ) {}

  @Get()
  async catalog(): Promise<Schemas['CatalogTree']> {
    return treeView(await this.tree.all());
  }

  @Post('categories')
  @HttpCode(201)
  async createCategory(@Body() body: Schemas['CategoryInput']): Promise<Schemas['Category']> {
    return categoryView(await this.edit.saveCategory(categoryInput(undefined, body)));
  }

  @Put('categories/:categoryId')
  async updateCategory(
    @Param('categoryId') id: string,
    @Body() body: Schemas['CategoryInput'],
  ): Promise<Schemas['Category']> {
    return categoryView(await this.edit.saveCategory(categoryInput(id, body)));
  }

  @Post('services')
  @HttpCode(201)
  async createService(@Body() body: Schemas['ServiceInput']): Promise<Schemas['Service']> {
    return serviceView(await this.edit.saveService(serviceInput(undefined, body)));
  }

  @Put('services/:serviceId')
  async updateService(
    @Param('serviceId') id: string,
    @Body() body: Schemas['ServiceInput'],
  ): Promise<Schemas['Service']> {
    return serviceView(await this.edit.saveService(serviceInput(id, body)));
  }

  // The input schema serves updates too, so `initialPrice` is optional there.
  @Post('sub-services')
  @HttpCode(201)
  async createSubService(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['SubServiceInput'],
  ): Promise<Schemas['SubService']> {
    if (body.initialPrice === undefined) {
      throw new DomainError(CatalogReason.PriceNegative);
    }
    const sub = await this.edit.createSubService(
      subServiceInput(body),
      body.initialPrice,
      me.accountId,
    );
    return subServiceView(sub);
  }

  @Put('sub-services/:subServiceId')
  async updateSubService(
    @Param('subServiceId') id: string,
    @Body() body: Schemas['SubServiceInput'],
  ): Promise<Schemas['SubService']> {
    return subServiceView(await this.edit.updateSubService({ ...subServiceInput(body), id }));
  }

  @Post('sub-services/:subServiceId/prices')
  @HttpCode(201)
  async changePrice(
    @CurrentPrincipal() me: Principal,
    @Param('subServiceId') id: string,
    @Body() body: Schemas['PriceInput'],
  ): Promise<Schemas['PriceVersion']> {
    return priceView(await this.prices.change(id, body.amount, me.accountId));
  }

  @Get('sub-services/:subServiceId/prices')
  async priceHistory(@Param('subServiceId') id: string): Promise<Schemas['PriceHistory']> {
    return { items: (await this.prices.history(id)).map(priceView) };
  }
}
