import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { decodeCursor, pageSize } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { CustomerConsole } from '../../app/customer-console';
import { ProviderConsole } from '../../app/provider-console';
import { adminErrors } from './error-map';
import { customerDetail, customerSummary, page, providerDetail, providerSummary } from './views';

type Schemas = components['schemas'];
type Query<Op extends keyof operations> = NonNullable<operations[Op]['parameters']['query']>;

/** Where a list continues, from the request's cursor. */
function after(cursor: string | undefined) {
  const c = decodeCursor(cursor);
  return c ? { afterAt: new Date(c.createdAt), afterId: c.id } : { afterAt: null, afterId: null };
}

/** Provider search, detail and status (A-05). */
@Controller('v1/admin/providers')
@MapErrors(adminErrors)
export class AdminProvidersController {
  constructor(private readonly providers: ProviderConsole) {}

  @Get()
  @RequirePermission('provider:read')
  async list(@Query() q: Query<'listAdminProviders'>): Promise<Schemas['AdminProviderList']> {
    const size = pageSize(q.limit);
    const rows = await this.providers.list({
      id: null,
      text: q.q ?? '',
      status: q.status ?? '',
      level: q.level ?? null,
      flagged: q.flagged ?? null,
      ...after(q.cursor),
      limit: size + 1,
    });
    const { items, nextCursor } = page(rows, size, (r) => r);
    const summaries = await Promise.all(
      items.map(async (r) => providerSummary(r, await this.providers.services(r.serviceIds))),
    );
    return nextCursor === undefined ? { items: summaries } : { items: summaries, nextCursor };
  }

  @Get(':providerId')
  @RequirePermission('provider:read')
  async get(@Param('providerId') id: string): Promise<Schemas['AdminProviderDetail']> {
    return providerDetail(await this.providers.detail(id));
  }

  @Post(':providerId/status')
  @RequirePermission('provider:manage')
  @HttpCode(200)
  async setStatus(
    @CurrentPrincipal() me: Principal,
    @Param('providerId') accountId: string,
    @Body() body: Schemas['AccountStatusChange'],
  ): Promise<Schemas['AdminProviderDetail']> {
    const d = await this.providers.setStatus({ actorId: me.accountId, accountId, ...body });
    return providerDetail(d);
  }
}

/** Customer search, detail and status (A-05). */
@Controller('v1/admin/customers')
@MapErrors(adminErrors)
export class AdminCustomersController {
  constructor(private readonly customers: CustomerConsole) {}

  @Get()
  @RequirePermission('customer:read')
  async list(@Query() q: Query<'listAdminCustomers'>): Promise<Schemas['AdminCustomerList']> {
    const size = pageSize(q.limit);
    const rows = await this.customers.list({
      id: null,
      text: q.q ?? '',
      status: q.status ?? '',
      ...after(q.cursor),
      limit: size + 1,
    });
    return page(rows, size, customerSummary);
  }

  @Get(':customerId')
  @RequirePermission('customer:read')
  async get(@Param('customerId') id: string): Promise<Schemas['AdminCustomerDetail']> {
    return customerDetail(await this.customers.detail(id));
  }

  @Post(':customerId/status')
  @RequirePermission('customer:manage')
  @HttpCode(200)
  async setStatus(
    @CurrentPrincipal() me: Principal,
    @Param('customerId') accountId: string,
    @Body() body: Schemas['AccountStatusChange'],
  ): Promise<Schemas['AdminCustomerDetail']> {
    const d = await this.customers.setStatus({ actorId: me.accountId, accountId, ...body });
    return customerDetail(d);
  }
}
