import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ProgressJob } from '../../app/progress';
import { ReadBookings } from '../../app/read-bookings';
import { RespondToRequests } from '../../app/respond';
import { type Booking } from '../../domain/booking';
import { Status } from '../../domain/states';
import { withNote } from './customer.controller';
import { bookingErrors } from './error-map';
import { bookingView, listView, page, receiptView, type Schemas } from './views';

type ListQuery = operations['listProviderJobs']['parameters']['query'];

const job = async (b: Promise<Booking>) => bookingView(await b, true);

/** A provider's jobs, from the request to the receipt (P-04 to P-09). */
@Controller('v1/provider/jobs')
@MapErrors(bookingErrors)
export class ProviderJobsController {
  constructor(
    private readonly reads: ReadBookings,
    private readonly responses: RespondToRequests,
    private readonly progress: ProgressJob,
  ) {}

  @Get()
  @RequirePermission('job:read:own')
  async list(@CurrentPrincipal() me: Principal, @Query() q: ListQuery) {
    const { size, page: p } = page(q.cursor, q.limit);
    const rows = await this.reads.list(me.accountId, 'provider', q.tab, p);
    return listView(rows, size, (r) => r.customerName);
  }

  @Get(':bookingId')
  @RequirePermission('job:read:own')
  async get(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    const { booking, reviewed } = await this.reads.detail(me.accountId, id, 'provider');
    return { ...bookingView(booking, true), reviewedByMe: reviewed };
  }

  @Post(':bookingId/accept')
  @HttpCode(200)
  @RequirePermission('job:respond')
  accept(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return job(this.responses.accept(me.accountId, id));
  }

  @Post(':bookingId/reject')
  @HttpCode(200)
  @RequirePermission('job:respond')
  reject(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['RejectInput'],
  ) {
    return job(this.responses.reject(me.accountId, id, withNote(b.reason, b.note)));
  }

  @Post(':bookingId/on-the-way')
  @HttpCode(200)
  @RequirePermission('job:progress')
  onTheWay(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return job(this.progress.advance(me.accountId, id, Status.OnTheWay));
  }

  @Post(':bookingId/arrived')
  @HttpCode(200)
  @RequirePermission('job:progress')
  arrived(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return job(this.progress.advance(me.accountId, id, Status.Arrived));
  }

  @Post(':bookingId/start')
  @HttpCode(200)
  @RequirePermission('job:progress')
  start(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['StartCode'],
  ) {
    return job(this.progress.start(me.accountId, id, b.code));
  }

  @Post(':bookingId/extras')
  @HttpCode(200)
  @RequirePermission('job:progress')
  extras(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['ExtrasInput'],
  ) {
    return job(this.progress.proposeExtras(me.accountId, id, b.items));
  }

  @Post(':bookingId/complete')
  @HttpCode(200)
  @RequirePermission('job:progress')
  complete(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['CompleteInput'],
  ) {
    return job(this.progress.complete(me.accountId, id, b.cashReceived));
  }

  @Post(':bookingId/cancel')
  @HttpCode(200)
  @RequirePermission('job:respond')
  cancel(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['ProviderCancelInput'],
  ) {
    const reason = withNote(b.reason, b.note);
    return job(this.responses.cancel('provider', me.accountId, id, reason));
  }

  @Get(':bookingId/receipt')
  @RequirePermission('job:read:own')
  async receipt(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return receiptView(await this.reads.receipt(me.accountId, id));
  }
}
