import { encodeCursor } from '../../../../platform/http/cursor';
import { type components } from '../../../../platform/http/openapi.gen';
import { type AuditEntry } from '../../../audit/contract/dto';
import { type BookingSummary } from '../../../booking/contract/dto';
import { type Service } from '../../../catalog/contract/dto';
import { type CustomerRecord } from '../../../customer/contract/admin-search';
import { type ProviderRecord } from '../../../provider/contract/admin-search';
import { type Item } from '../../../verification/contract/dto';
import { type CustomerDetail } from '../../app/customer-console';
import { type ProviderDetail } from '../../app/provider-console';
import { type Complaint, ticketNumber } from '../../domain/complaint';

type Schemas = components['schemas'];

/** A complaint as the API shows it. */
export function complaintView(c: Complaint): Schemas['Complaint'] {
  return {
    id: c.id,
    ticketNumber: ticketNumber(c),
    bookingId: c.bookingId,
    reporterRole: c.reporterRole,
    reporterId: c.reporterId,
    againstId: c.againstId,
    reason: c.reason as Schemas['ComplaintReason'],
    description: c.description,
    photoMediaIds: [...c.photos],
    status: c.status,
    ...(c.assigneeId === null ? {} : { assigneeId: c.assigneeId }),
    resolution: c.resolution,
    verified: c.verified,
    comments: c.comments.map((m) => ({
      authorId: m.authorId,
      body: m.body,
      at: m.at.toISOString(),
    })),
    createdAt: c.createdAt.toISOString(),
    ...(c.resolvedAt === null ? {} : { resolvedAt: c.resolvedAt.toISOString() }),
  };
}

/**
 * Cuts a page from `rows`, fetched one longer than `size`, and adds the cursor of the
 * last shown row when more follow.
 */
export function page<R extends { id: string; createdAt: Date }, V>(
  rows: readonly R[],
  size: number,
  view: (r: R) => V,
): { items: V[]; nextCursor?: string } {
  const shown = rows.slice(0, size);
  const last = shown.at(-1);
  const items = shown.map(view);
  return rows.length > size && last ? { items, nextCursor: encodeCursor(last) } : { items };
}

function serviceRef(s: Service): Schemas['ServiceRef'] {
  return { id: s.id, name: { en: s.name.en, bn: s.name.bn } };
}

/** A provider row of the admin list. */
export function providerSummary(r: ProviderRecord, services: Service[]) {
  return {
    id: r.id,
    name: r.name,
    phone: r.phone,
    status: r.status as Schemas['AccountStatus'],
    level: r.level,
    services: services.map(serviceRef),
    rating: r.rating,
    completedJobs: r.completedJobs,
    flaggedForReview: r.flagged,
    online: r.online,
    createdAt: r.createdAt.toISOString(),
  } satisfies Schemas['AdminProviderSummary'];
}

/** A customer row of the admin list. */
export function customerSummary(r: CustomerRecord): Schemas['AdminCustomerSummary'] {
  return {
    id: r.id,
    name: r.name,
    phone: r.phone,
    status: r.status as Schemas['AccountStatus'],
    bookings: r.bookings,
    createdAt: r.createdAt.toISOString(),
  };
}

function bookingView(b: BookingSummary): Schemas['BookingSummary'] {
  return {
    id: b.id,
    number: b.number,
    status: b.status,
    serviceName: { en: b.serviceName.en, bn: b.serviceName.bn },
    total: b.totalPaisa,
    createdAt: b.createdAt.toISOString(),
  };
}

function historyView(e: AuditEntry): Schemas['AuditEntry'] {
  return {
    id: e.id,
    at: e.at.toISOString(),
    ...(e.actorId === null ? {} : { actorId: e.actorId }),
    actorRole: e.actorRole,
    action: e.action,
    subjectType: e.subjectType,
    subjectId: e.subjectId,
    reason: e.reason,
    ...(e.before === null ? {} : { before: { ...e.before } }),
    ...(e.after === null ? {} : { after: { ...e.after } }),
  };
}

function itemView(it: Item): Schemas['VerificationItem'] {
  return {
    type: it.type,
    status: it.status as Schemas['ItemStatus'],
    required: it.required,
    ...(it.reason === '' ? {} : { rejectionReason: it.reason }),
    ...(it.decidedAt === null ? {} : { decidedAt: it.decidedAt.toISOString() }),
    ...(it.expiresAt === null ? {} : { expiresAt: it.expiresAt.toISOString() }),
  };
}

/** The admin provider record. */
export function providerDetail(d: ProviderDetail): Schemas['AdminProviderDetail'] {
  return {
    summary: providerSummary(d.record, d.services),
    gender: d.profile.gender,
    experienceYears: d.profile.experienceYears,
    items: d.items.map(itemView),
    recentBookings: d.recent.map(bookingView),
    complaints: d.complaints,
    cancellations30d: d.cancellations30d,
    statusHistory: d.history.map(historyView),
  };
}

/** The admin customer record; the rating shows once providers have rated them. */
export function customerDetail(d: CustomerDetail): Schemas['AdminCustomerDetail'] {
  const summary = customerSummary(d.record);
  return {
    summary: d.rating.count > 0 ? { ...summary, rating: d.rating.average } : summary,
    recentBookings: d.recent.map(bookingView),
    complaints: d.complaints.map(complaintView),
    statusHistory: d.history.map(historyView),
  };
}
