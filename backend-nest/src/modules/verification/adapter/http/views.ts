import { decodeCursor, pageSize } from '../../../../platform/http/cursor';
import { type components } from '../../../../platform/http/openapi.gen';
import { type Status } from '../../app/status';
import { type QueueEntry } from '../../app/review';
import { ITEM_TYPES, type Item, required } from '../../domain/items';
import { type Session } from '../../domain/level2';
import { itemOf } from '../../domain/state';
import { type Service } from '../../port/peers';
import { type Page } from '../../port/repository';

type Schemas = components['schemas'];

/** One item's review state. */
export function itemView(it: Item): Schemas['VerificationItem'] {
  return {
    type: it.type as Schemas['ItemType'],
    status: it.status as Schemas['ItemStatus'],
    required: required(it.type),
    ...(it.reason === '' ? {} : { rejectionReason: it.reason }),
    ...(it.decidedAt === null ? {} : { decidedAt: it.decidedAt.toISOString() }),
    ...(it.expiresAt === null ? {} : { expiresAt: it.expiresAt.toISOString() }),
  };
}

function badge(level: number): Schemas['Badge'] {
  if (level === 2) {
    return 'verified_pro';
  }
  return level === 1 ? 'verified' : 'none';
}

/** A Level 2 session; the result details appear once it has one. */
export function sessionView(s: Session): Schemas['Level2Session'] {
  return {
    id: s.id,
    providerId: s.providerId,
    serviceId: s.serviceId,
    scheduledAt: s.scheduledAt.toISOString(),
    location: s.location,
    status: s.status as Schemas['Level2Session']['status'],
    ...(s.decidedBy === null ? {} : { decidedBy: s.decidedBy }),
    ...(s.result === ''
      ? {}
      : {
          result: s.result as Schemas['Level2Result'],
          notes: s.notes,
          checklist: s.checklist.map((c) => ({ item: c.item, passed: c.passed })),
        }),
  };
}

/** The provider's verification screen (M14/P-03). */
export function statusView(s: Status): Schemas['VerificationStatus'] {
  return {
    level: s.level,
    badge: badge(s.level),
    items: ITEM_TYPES.map((t) => itemView(itemOf(s, t))),
    canReceiveBookings: s.canReceiveBookings,
    level2: {
      eligible: s.level2Eligible,
      ...(s.retryAfter === null ? {} : { retryAfter: s.retryAfter.toISOString() }),
      ...(s.nextSession === null ? {} : { nextSession: sessionView(s.nextSession) }),
    },
  };
}

function serviceRef(s: Service): Schemas['ServiceRef'] {
  return { id: s.id, name: { en: s.name.en, bn: s.name.bn } };
}

/** One row of the review queue (A-03). */
export function queueView(r: QueueEntry): Schemas['VerificationQueueItem'] {
  return {
    providerId: r.providerId,
    name: r.name,
    pendingItems: r.pendingItems as Schemas['ItemType'][],
    submittedAt: r.submittedAt.toISOString(),
    ageHours: r.ageHours,
    services: r.services.map(serviceRef),
  };
}

/** A keyset page asking for one look-ahead row. */
export function pageOf(q: { cursor?: string; limit?: number }): { size: number; page: Page } {
  const cursor = decodeCursor(q.cursor);
  const size = pageSize(q.limit);
  const at = cursor ? new Date(cursor.createdAt) : null;
  return { size, page: { at, id: cursor?.id ?? null, limit: size + 1 } };
}
