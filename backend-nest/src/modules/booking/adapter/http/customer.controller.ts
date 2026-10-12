import { Body, Controller, Get, Headers, HttpCode, Param, Post, Query } from '@nestjs/common';
import { DomainError } from '../../../../platform/errors/domain-error';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { CreateBooking } from '../../app/create-booking';
import { ProgressJob } from '../../app/progress';
import { ReadBookings } from '../../app/read-bookings';
import { RespondToRequests } from '../../app/respond';
import { BookingReasons } from '../../domain/reasons';
import { bookingErrors } from './error-map';
import { bookingView, listView, page, receiptView, type Schemas } from './views';

type ListQuery = operations['listCustomerBookings']['parameters']['query'];

/** Joins a cancel or reject reason with the optional note, as Go stored it. */
export function withNote(reason: string, note?: string): string {
  return note ? `${reason}: ${note}` : reason;
}

/** A customer's bookings (C-06 to C-13). */
@Controller('v1/customer/bookings')
@MapErrors(bookingErrors)
export class CustomerBookingsController {
  constructor(
    private readonly creator: CreateBooking,
    private readonly reads: ReadBookings,
    private readonly responses: RespondToRequests,
    private readonly progress: ProgressJob,
  ) {}

  @Post()
  @HttpCode(201)
  @RequirePermission('booking:create')
  async create(
    @CurrentPrincipal() me: Principal,
    @Headers('idempotency-key') key: string,
    @Body() b: Schemas['BookingCreate'],
  ): Promise<Schemas['Booking']> {
    const at = b.timing === 'scheduled' ? b.scheduledAt : undefined;
    if (b.timing === 'scheduled' && at === undefined) {
      throw new DomainError(BookingReasons.Invalid);
    }
    const { booking } = await this.creator.execute({
      customerId: me.accountId,
      providerId: b.providerId,
      serviceId: b.serviceId,
      addressId: b.addressId,
      items: b.items,
      scheduledAt: at === undefined ? null : new Date(at),
      note: b.note ?? '',
      idempotencyKey: key,
    });
    return bookingView(booking, false);
  }

  @Get()
  @RequirePermission('booking:read:own')
  async list(@CurrentPrincipal() me: Principal, @Query() q: ListQuery) {
    const { size, page: p } = page(q.cursor, q.limit);
    const rows = await this.reads.list(me.accountId, 'customer', q.tab, p);
    return listView(rows, size, (r) => r.providerName);
  }

  @Get(':bookingId')
  @RequirePermission('booking:read:own')
  async get(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    const { booking, reviewed } = await this.reads.detail(me.accountId, id, 'customer');
    return { ...bookingView(booking, false), reviewedByMe: reviewed };
  }

  @Get(':bookingId/start-code')
  @RequirePermission('booking:read:own')
  async startCode(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return { code: await this.reads.startCode(me.accountId, id) };
  }

  @Post(':bookingId/cancel')
  @HttpCode(200)
  @RequirePermission('booking:cancel:own')
  async cancel(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['CustomerCancelInput'],
  ) {
    const reason = withNote(b.reason, b.note);
    return bookingView(await this.responses.cancel('customer', me.accountId, id, reason), false);
  }

  @Post(':bookingId/extras/decision')
  @HttpCode(200)
  @RequirePermission('booking:update:own')
  async decide(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') id: string,
    @Body() b: Schemas['ExtrasDecisionInput'],
  ) {
    const booking = await this.progress.decideExtras(me.accountId, id, b.proposalId, b.approve);
    return bookingView(booking, false);
  }

  @Get(':bookingId/receipt')
  @RequirePermission('booking:read:own')
  async receipt(@CurrentPrincipal() me: Principal, @Param('bookingId') id: string) {
    return receiptView(await this.reads.receipt(me.accountId, id));
  }
}
