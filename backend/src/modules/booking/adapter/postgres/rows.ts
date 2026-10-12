import { type SqlClient } from '../../../../platform/db/database';
import { type Booking, type Line, type Proposal } from '../../domain/booking';
import { type Status } from '../../domain/states';
import { type Summary } from '../../port/repository';
import {
  type BookingByIDRow,
  bookingByID,
  insertItem,
  insertTimeline,
  itemsByBooking,
  type ItemsByBookingRow,
  type ListBookingsRow,
  proposalsByBooking,
  timelineByBooking,
  updateBooking,
  upsertProposal,
} from './sqlc/queries_sql';

function toBooking(r: BookingByIDRow): Booking {
  return {
    ...r,
    number: Number(r.number),
    customer: { id: r.customerId, name: r.customerName, phone: r.customerPhone },
    provider: { id: r.providerId, name: r.providerName, phone: r.providerPhone },
    serviceName: { en: r.serviceNameEn, bn: r.serviceNameBn },
    address: {
      id: r.addressId,
      area: r.addressArea,
      line1: r.addressLine1,
      line2: r.addressLine2,
      location: { lat: r.lat, lng: r.lng },
    },
    status: r.status as Status,
    scheduled: r.timing === 'scheduled',
    totalPaisa: Number(r.totalPaisa),
    codeAttempts: r.startCodeAttempts,
    codeLockedUntil: r.startCodeLockedUntil,
    cancelledBy: r.cancelledBy ?? '',
    lines: [],
    proposals: [],
    timeline: [],
    providerActiveJobs: 0,
    newEvents: [],
  };
}

function toLine(r: ItemsByBookingRow): Line {
  return {
    ...r,
    name: { en: r.nameEn, bn: r.nameBn },
    unitPaisa: Number(r.unitPricePaisa),
    totalPaisa: Number(r.totalPaisa),
  };
}

/**
 * Reads a booking with its lines, proposals and timeline, or returns undefined. Lines of
 * an approved proposal are part of the bill; lines of other proposals stay with it.
 */
export async function load(db: SqlClient, id: string): Promise<Booking | undefined> {
  const row = await bookingByID(db, { id });
  if (row === null) {
    return undefined;
  }
  const b = toBooking(row);
  for (const p of await proposalsByBooking(db, { bookingId: id })) {
    const status = p.status as Proposal['status'];
    b.proposals.push({ ...p, status, addedPaisa: Number(p.addedPaisa), lines: [] });
  }
  for (const item of await itemsByBooking(db, { bookingId: id })) {
    const l = toLine(item);
    const p = b.proposals.find((x) => x.id === l.proposalId);
    p?.lines.push(l);
    if (p === undefined || p.status === 'approved') {
      b.lines.push(l);
    }
  }
  b.timeline.push(...(await timelineByBooking(db, { bookingId: id })));
  return b;
}

function insertLine(tx: SqlClient, bookingId: string, l: Line): Promise<void> {
  return insertItem(tx, {
    ...l,
    bookingId,
    nameEn: l.name.en,
    nameBn: l.name.bn,
    unitPricePaisa: String(l.unitPaisa),
    totalPaisa: String(l.totalPaisa),
  });
}

/**
 * Writes lines, proposals and new timeline entries; lines are immutable, so inserting
 * known ones again does nothing.
 */
export async function saveParts(tx: SqlClient, b: Booking): Promise<void> {
  for (const p of b.proposals) {
    await upsertProposal(tx, { ...p, bookingId: b.id, addedPaisa: String(p.addedPaisa) });
    for (const l of p.lines) {
      await insertLine(tx, b.id, l);
    }
  }
  for (const l of b.lines) {
    await insertLine(tx, b.id, l);
  }
  for (const e of b.newEvents) {
    await insertTimeline(tx, { ...e, bookingId: b.id });
  }
}

/** Writes the booking's changing columns and its parts. */
export async function update(tx: SqlClient, b: Booking, now: Date): Promise<void> {
  await updateBooking(tx, {
    ...b,
    totalPaisa: String(b.totalPaisa),
    startCodeAttempts: b.codeAttempts,
    startCodeLockedUntil: b.codeLockedUntil,
    cancelledBy: b.cancelledBy === '' ? null : b.cancelledBy,
    updatedAt: now,
  });
  await saveParts(tx, b);
}

/** A list row. */
export function toSummary(r: ListBookingsRow): Summary {
  return {
    ...r,
    number: Number(r.number),
    serviceName: { en: r.serviceNameEn, bn: r.serviceNameBn },
    scheduled: r.timing === 'scheduled',
    totalPaisa: Number(r.totalPaisa),
  };
}
