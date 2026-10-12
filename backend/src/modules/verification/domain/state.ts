import { type Item, level, missingItem } from './items';
import { type Session } from './level2';

/** An uploaded file attached to an item, e.g. kind nid_front. */
export interface Document {
  readonly id: string;
  readonly itemType: string;
  readonly kind: string;
  readonly mediaId: string;
  readonly createdAt: Date;
}

/** The encrypted NID number and its keyed hash. */
export interface NidRecord {
  readonly ciphertext: Buffer;
  readonly hash: string;
}

/**
 * Everything verification knows about one provider. A change edits it in place and the
 * repository saves it together with the change's events.
 */
export interface State {
  readonly providerId: string;
  items: Map<string, Item>;
  level: number;
  level2PassedAt: Date | null;
  blocked: boolean;
  serviceIds: string[];
  submittedAt: Date | null;
  sessions: Session[];
  documents: Document[];
  /** Replace the current documents of their item types when saved. */
  newDocuments: Document[];
  nid: NidRecord | null;
  /** Marks a new NID to save. */
  nidChanged: boolean;
}

/** The state of a provider verification has not seen yet. */
export function newState(providerId: string): State {
  return {
    providerId,
    items: new Map(),
    level: 0,
    level2PassedAt: null,
    blocked: false,
    serviceIds: [],
    submittedAt: null,
    sessions: [],
    documents: [],
    newDocuments: [],
    nid: null,
    nidChanged: false,
  };
}

/** An item, missing when never submitted. */
export function itemOf(s: State, type: string): Item {
  return s.items.get(type) ?? missingItem(type);
}

/** Updates the level and returns the old one when it changed. */
export function recalc(s: State): number | undefined {
  const from = s.level;
  s.level = level(s.items, s.level2PassedAt !== null);
  return from === s.level ? undefined : from;
}

/** PRD §6.1/§6.4: not blocked and at least `minLevel`, never below Level 1. */
export function canReceiveBookings(s: State, minLevel: number): boolean {
  return !s.blocked && s.level >= Math.max(1, minLevel);
}
