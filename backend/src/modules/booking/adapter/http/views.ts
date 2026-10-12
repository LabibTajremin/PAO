import { decodeCursor, encodeCursor, pageSize } from '../../../../platform/http/cursor';
import { type components } from '../../../../platform/http/openapi.gen';
import { bookingNumber } from '../../app/access';
import {
  type Booking,
  cancellable,
  contactsShared,
  type Line,
  type Party,
  pending,
} from '../../domain/booking';
import { Actor } from '../../domain/states';
import { type Page, type Summary } from '../../port/repository';

/** Spec schemas, shorter. */
export type Schemas = components['schemas'];

/** A page request from `cursor` and `limit`; the extra row tells whether more follow. */
export function page(cursor: string | undefined, limit: number | undefined) {
  const c = decodeCursor(cursor);
  const size = pageSize(limit);
  const p: Page = { at: c ? new Date(c.createdAt) : null, id: c?.id ?? null, limit: size + 1 };
  return { size, page: p };
}

/** The cursor after the last shown row when the look-ahead row came back. */
export function nextCursor<T extends { id: string }>(
  rows: readonly T[],
  size: number,
  at: (row: T) => Date,
): string | undefined {
  const last = rows[size - 1];
  return rows.length > size && last
    ? encodeCursor({ createdAt: at(last), id: last.id })
    : undefined;
}

function iso(t: Date | null): string | undefined {
  return t?.toISOString();
}

/** A line as the apps show it. */
export function lineView(l: Line): Schemas['BookingItem'] {
  return {
    subServiceId: l.subServiceId,
    priceVersionId: l.priceVersionId,
    name: l.name,
    unit: l.unit as Schemas['PriceUnit'],
    quantity: l.quantity,
    unitPrice: l.unitPaisa,
    total: l.totalPaisa,
    extra: l.extra,
  };
}

/** A party; the phone only when it is shared. */
export function partyView(p: Party, showPhone: boolean): Schemas['BookingParty'] {
  return showPhone ? { id: p.id, name: p.name, phone: p.phone } : { id: p.id, name: p.name };
}

function pendingView(b: Booking): Schemas['ExtrasProposal'] | undefined {
  const p = pending(b);
  return (
    p && {
      id: p.id,
      items: p.lines.map(lineView),
      addedTotal: p.addedPaisa,
      newTotal: b.totalPaisa + p.addedPaisa,
      status: p.status,
      proposedAt: p.proposedAt.toISOString(),
    }
  );
}

function addressView(b: Booking, exact: boolean): Schemas['BookingAddress'] {
  const { area, line1, line2, location } = b.address;
  return exact ? { area, line1, line2, location } : { area };
}

/**
 * A booking for one side. The provider sees the exact address, and either side the
 * other's phone, only once they are shared (PRD §5, §11).
 */
export function bookingView(b: Booking, asProvider: boolean): Schemas['Booking'] {
  const open = contactsShared(b);
  return {
    id: b.id,
    number: bookingNumber(b.number),
    status: b.status,
    serviceId: b.serviceId,
    serviceName: b.serviceName,
    serviceModel: b.serviceModel as Schemas['ServiceModel'],
    provider: partyView(b.provider, open),
    customer: partyView(b.customer, open),
    items: b.lines.map(lineView),
    total: b.totalPaisa,
    timing: b.scheduled ? 'scheduled' : 'asap',
    scheduledAt: iso(b.scheduledAt),
    endsAt: iso(b.endsAt),
    address: addressView(b, !asProvider || open),
    note: b.note,
    acceptDeadline: b.acceptDeadline.toISOString(),
    pendingExtras: pendingView(b),
    cancellable: cancellable(b, asProvider ? Actor.Provider : Actor.Customer),
    paymentMethod: 'cash',
    cashReceived: b.cashReceived,
    createdAt: b.createdAt.toISOString(),
    timeline: b.timeline.map((e) => ({
      status: e.status as Schemas['BookingStatus'],
      at: e.at.toISOString(),
      actor: e.actor as Schemas['TimelineEntry']['actor'],
      ...(e.reason === '' ? {} : { reason: e.reason }),
    })),
  };
}

/** A completed booking's receipt. */
export function receiptView(b: Booking): Schemas['Receipt'] {
  return {
    bookingId: b.id,
    number: bookingNumber(b.number),
    completedAt: (b.completedAt ?? b.createdAt).toISOString(),
    serviceName: b.serviceName,
    providerName: b.provider.name,
    customerName: b.customer.name,
    area: b.address.area,
    items: b.lines.map(lineView),
    total: b.totalPaisa,
    paymentMethod: 'cash',
  };
}

/** A page of summaries; `counterpart` names the other side of each row. */
export function listView(
  rows: readonly Summary[],
  size: number,
  counterpart: (r: Summary) => string,
): Schemas['BookingList'] {
  return {
    items: rows.slice(0, size).map((r) => ({
      id: r.id,
      number: bookingNumber(r.number),
      status: r.status as Schemas['BookingStatus'],
      serviceName: r.serviceName,
      counterpartName: counterpart(r),
      timing: r.scheduled ? 'scheduled' : 'asap',
      scheduledAt: iso(r.scheduledAt),
      total: r.totalPaisa,
      createdAt: r.createdAt.toISOString(),
    })),
    nextCursor: nextCursor(rows, size, (r) => r.createdAt),
  };
}
