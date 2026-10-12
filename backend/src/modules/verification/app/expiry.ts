import { Injectable } from '@nestjs/common';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { type DocumentExpiry } from '../../../platform/testing/test-hooks';
import { type ItemType } from '../contract/dto';
import {
  type DocumentExpired,
  type DocumentExpiring,
  VerificationEvents,
} from '../contract/events';
import { hasExpired, ItemStatus } from '../domain/items';
import { States } from './states';

/** When providers hear that a document is about to expire, in days (P-11). */
export const REMINDER_DAYS = [30, 7, 1];

const DAY_MS = 24 * 60 * 60 * 1000;

/** The daily expiry sweep and its reminders (PRD §6.4). */
@Injectable()
export class ExpireDocuments implements DocumentExpiry {
  constructor(private readonly states: States) {}

  /** Expires approved items past their date; the level drops and presence follows. */
  expireDocuments(): Promise<void> {
    return this.expireDocumentsAt(this.states.clock.now());
  }

  /**
   * Runs the sweep as of `now`, so end-to-end tests can reach a document's expiry without
   * waiting for it.
   */
  async expireDocumentsAt(now: Date): Promise<void> {
    for (const id of await this.states.repo.expiredBy(now)) {
      await this.states.change(id, 'document_expired', (st) => {
        const events: DomainEvent[] = [];
        for (const [type, it] of st.items) {
          if (hasExpired(it, now)) {
            st.items.set(type, { ...it, status: ItemStatus.Expired });
            events.push(expired(id, type));
          }
        }
        return events;
      });
    }
  }

  /** Sends each reminder once per document and threshold. */
  async remindExpiring(): Promise<void> {
    const now = this.states.clock.now().getTime();
    for (const days of REMINDER_DAYS) {
      const from = new Date(now + (days - 1) * DAY_MS);
      const items = await this.states.repo.expiringBetween(from, new Date(now + days * DAY_MS));
      for (const it of items) {
        const e: DocumentExpiring = {
          name: VerificationEvents.DocumentExpiring,
          providerId: it.providerId,
          item: it.itemType as ItemType,
          daysLeft: days,
        };
        await this.states.repo.remindOnce(it, days, e);
      }
    }
  }
}

function expired(providerId: string, item: string): DocumentExpired {
  return { name: VerificationEvents.DocumentExpired, providerId, item: item as ItemType };
}
