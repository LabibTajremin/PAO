import { Controller, Get, Param, Query } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { FindNearby } from '../../app/find-nearby';
import { ReadBookings } from '../../app/read-bookings';
import { addDays, dayStart } from '../../domain/earnings';
import { calendarDay } from './earnings.controller';
import { bookingErrors } from './error-map';
import { bookingView, listView, page, partyView, type Schemas } from './views';

type NearbyQuery = operations['findNearbyProviders']['parameters']['query'];
type MonitorQuery = NonNullable<operations['listAdminBookings']['parameters']['query']>;

/** Search only returns verified providers, so the badge follows the level. */
export function badge(level: number): Schemas['Badge'] {
  return level >= 2 ? 'verified_pro' : 'verified';
}

/** Providers around the customer with the fixed price of the job (C10). */
@Controller('v1/customer/providers')
@MapErrors(bookingErrors)
export class NearbyController {
  constructor(private readonly finder: FindNearby) {}

  @Get('nearby')
  @RequirePermission('provider:browse')
  async nearby(
    @CurrentPrincipal() me: Principal,
    @Query() q: NearbyQuery,
  ): Promise<Schemas['NearbyProviders']> {
    const at = q.lat !== undefined && q.lng !== undefined ? { lat: q.lat, lng: q.lng } : null;
    const r = await this.finder.execute({
      customerId: me.accountId,
      serviceId: q.serviceId,
      subServiceId: q.subServiceId,
      quantity: q.quantity,
      addressId: q.addressId ?? null,
      at,
      byRating: q.sort === 'rating',
      limit: page(undefined, q.limit).size,
    });
    const { subServiceId, quantity, unitPaisa, totalPaisa } = r.price;
    return {
      items: r.providers.map(({ photoMediaId: _photo, photoUrl, ...c }) => ({
        ...c,
        badge: badge(c.level),
        ...(photoUrl === '' ? {} : { photoUrl }),
      })),
      priceSummary: { subServiceId, quantity, unitPrice: unitPaisa, total: totalPaisa },
    };
  }
}

/** The admin bookings monitor (A-06; ADR-0026 has booking serve it). */
@Controller('v1/admin/bookings')
@MapErrors(bookingErrors)
@RequirePermission('booking:read:any')
export class AdminBookingsController {
  constructor(private readonly reads: ReadBookings) {}

  /** Filter dates are Asia/Dhaka days; `to` includes its whole day. */
  @Get()
  async list(@Query() q: MonitorQuery): Promise<Schemas['BookingList']> {
    const { size, page: p } = page(q.cursor, q.limit);
    const from = calendarDay(q.from);
    const to = calendarDay(q.to);
    const rows = await this.reads.monitor(
      {
        status: q.status ?? null,
        serviceId: q.serviceId ?? null,
        from: from && dayStart(from),
        until: to && dayStart(addDays(to, 1)),
        area: q.area ?? '',
      },
      p,
    );
    return listView(rows, size, (r) => `${r.customerName} → ${r.providerName}`);
  }

  /** Support sees both parties' contact details and the full timeline. */
  @Get(':bookingId')
  async get(@Param('bookingId') id: string): Promise<Schemas['Booking']> {
    const b = await this.reads.get(id);
    return {
      ...bookingView(b, false),
      provider: partyView(b.provider, true),
      customer: partyView(b.customer, true),
    };
  }
}
