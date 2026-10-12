import { type SqlClient } from '../../../../platform/db/database';
import { type CheckItem, type Session } from '../../domain/level2';
import { newState, type State } from '../../domain/state';
import {
  currentDocuments,
  insertDocument,
  itemsByProvider,
  nIDByProvider,
  retireDocuments,
  saveLevel,
  type SessionByIDRow,
  sessionsByProvider,
  upsertItem,
  upsertNID,
  upsertSession,
} from './sqlc/queries_sql';

/** A stored session; `checklist` is jsonb. */
export function toSession(s: SessionByIDRow): Session {
  return {
    ...s,
    result: s.result ?? '',
    checklist: (s.checklist ?? []) as CheckItem[],
    photos: s.photoMediaIds,
  };
}

/** The columns of a provider's level row. */
type LevelRow = Pick<State, 'level' | 'level2PassedAt' | 'blocked' | 'serviceIds' | 'submittedAt'>;

/** Reads a provider's state; the level row comes from the caller so `change` can lock it. */
export async function loadState(db: SqlClient, id: string, lvl: LevelRow): Promise<State> {
  const st = newState(id);
  Object.assign(st, {
    level: lvl.level,
    level2PassedAt: lvl.level2PassedAt,
    blocked: lvl.blocked,
    serviceIds: lvl.serviceIds,
    submittedAt: lvl.submittedAt,
  });
  for (const r of await itemsByProvider(db, { providerId: id })) {
    st.items.set(r.itemType, {
      type: r.itemType,
      status: r.status,
      reason: r.rejectionReason,
      fields: (r.fields ?? {}) as Record<string, string>,
      submittedAt: r.submittedAt,
      decidedAt: r.decidedAt,
      decidedBy: r.decidedBy,
      expiresAt: r.expiresAt,
    });
  }
  st.sessions = (await sessionsByProvider(db, { providerId: id })).map(toSession);
  st.documents = await currentDocuments(db, { providerId: id });
  const nid = await nIDByProvider(db, { providerId: id });
  st.nid = nid === null ? null : { ciphertext: nid.nidCiphertext, hash: nid.nidHash };
  return st;
}

/**
 * Writes the whole state; rows are few per provider, so rewriting them all keeps the code
 * free of change tracking.
 */
export async function saveState(db: SqlClient, st: State, now: Date): Promise<void> {
  const providerId = st.providerId;
  await saveLevel(db, { ...st, providerId, updatedAt: now });
  for (const [itemType, it] of st.items) {
    await upsertItem(db, {
      ...it,
      providerId,
      itemType,
      rejectionReason: it.reason,
      fields: JSON.stringify(it.fields),
    });
  }
  await saveDocuments(db, st, now);
  for (const s of st.sessions) {
    await upsertSession(db, {
      ...s,
      result: s.result === '' ? null : s.result,
      checklist: JSON.stringify(s.checklist),
      photoMediaIds: [...s.photos],
    });
  }
}

async function saveDocuments(db: SqlClient, st: State, now: Date): Promise<void> {
  const providerId = st.providerId;
  const itemTypes = st.newDocuments.map((d) => d.itemType);
  await retireDocuments(db, { providerId, itemTypes });
  for (const d of st.newDocuments) {
    await insertDocument(db, { ...d, providerId });
  }
  if (st.nidChanged && st.nid !== null) {
    const { ciphertext, hash } = st.nid;
    await upsertNID(db, { providerId, nidCiphertext: ciphertext, nidHash: hash, updatedAt: now });
  }
}
