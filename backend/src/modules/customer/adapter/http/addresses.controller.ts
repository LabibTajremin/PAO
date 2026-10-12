import { Body, Controller, Delete, Get, HttpCode, Param, Post, Put, Query } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { type AddressInput, SavedAddresses } from '../../app/addresses';
import { ServiceArea } from '../../app/service-area';
import { type Address } from '../../domain/customer';
import { customerErrors } from './error-map';

type Schemas = components['schemas'];
type AddressView = Schemas['Address'];

function addressView(a: Address): AddressView {
  return {
    id: a.id,
    label: a.label as AddressView['label'],
    line1: a.line1,
    line2: a.line2,
    area: a.area,
    location: { lat: a.location.lat, lng: a.location.lng },
    isDefault: a.isDefault,
  };
}

function addressInput(body: Schemas['AddressInput']): AddressInput {
  return {
    label: body.label,
    line1: body.line1,
    line2: body.line2 ?? '',
    area: body.area ?? '',
    location: body.location,
    isDefault: body.isDefault === true,
  };
}

/** Saved addresses (C-02). */
@Controller('v1/customer/addresses')
@MapErrors(customerErrors)
export class AddressesController {
  constructor(private readonly addresses: SavedAddresses) {}

  @Get()
  @RequirePermission('address:manage:own')
  async list(@CurrentPrincipal() me: Principal): Promise<Schemas['AddressList']> {
    return { items: (await this.addresses.list(me.accountId)).map(addressView) };
  }

  @Post()
  @RequirePermission('address:manage:own')
  @HttpCode(201)
  async create(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['AddressInput'],
  ): Promise<AddressView> {
    return addressView(await this.addresses.add(me.accountId, addressInput(body)));
  }

  @Put(':addressId')
  @RequirePermission('address:manage:own')
  async update(
    @CurrentPrincipal() me: Principal,
    @Param('addressId') id: string,
    @Body() body: Schemas['AddressInput'],
  ): Promise<AddressView> {
    return addressView(await this.addresses.update(me.accountId, id, addressInput(body)));
  }

  @Delete(':addressId')
  @RequirePermission('address:manage:own')
  @HttpCode(204)
  async delete(@CurrentPrincipal() me: Principal, @Param('addressId') id: string): Promise<void> {
    await this.addresses.delete(me.accountId, id);
  }

  @Post(':addressId/default')
  @RequirePermission('address:manage:own')
  @HttpCode(200)
  async setDefault(
    @CurrentPrincipal() me: Principal,
    @Param('addressId') id: string,
  ): Promise<AddressView> {
    return addressView(await this.addresses.setDefault(me.accountId, id));
  }
}

/** The launch-area check (C35). */
@Controller('v1/customer/service-area')
export class ServiceAreaController {
  constructor(private readonly area: ServiceArea) {}

  @Get()
  @RequirePermission('catalog:read')
  async check(@Query() q: { lat: number; lng: number }): Promise<Schemas['ServiceAreaCheck']> {
    return { covered: await this.area.covers({ lat: q.lat, lng: q.lng }) };
  }
}
