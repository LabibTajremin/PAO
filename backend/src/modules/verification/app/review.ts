import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Provider } from '../../provider/contract/dto';
import { type ItemType } from '../contract/dto';
import {
  type DocumentApproved,
  type DocumentRejected,
  VerificationEvents,
} from '../contract/events';
import { decided } from '../domain/items';
import { VerificationReasons } from '../domain/reasons';
import { itemOf, type State } from '../domain/state';
import { CIPHER, type Cipher, PROVIDERS, type Providers, type Service } from '../port/peers';
import { type Page, type QueueFilter, type QueueRow } from '../port/repository';
import { States } from './states';

const HOUR_MS = 60 * 60 * 1000;

/** A queue row with the provider's name and services. */
export interface QueueEntry extends QueueRow {
  readonly name: string;
  readonly services: Service[];
  readonly ageHours: number;
}

/** Everything a verifier sees for one provider (A06); the NID is decrypted only here. */
export interface Review extends State {
  readonly provider: Provider;
  readonly nidNumber: string;
}

/** A verifier's decision on one item. */
export interface ItemDecision {
  readonly providerId: string;
  readonly item: string;
  readonly actor: string;
  readonly approve: boolean;
  readonly reason: string;
}

/** The review queue and per-item decisions (A-03, A06). */
@Injectable()
export class ReviewItems {
  constructor(
    private readonly states: States,
    @Inject(PROVIDERS) private readonly providers: Providers,
    @Inject(CIPHER) private readonly cipher: Cipher,
  ) {}

  /** Submitted providers with pending items, oldest first. */
  async queue(f: QueueFilter, p: Page): Promise<QueueEntry[]> {
    const out: QueueEntry[] = [];
    for (const r of await this.states.repo.queue(f, p)) {
      const prov = await this.providers.get(r.providerId);
      const ageMs = this.states.clock.now().getTime() - r.submittedAt.getTime();
      const services: Service[] = [];
      for (const id of r.serviceIds) {
        services.push(await this.states.catalog.service(id));
      }
      out.push({ ...r, name: prov.fullName, services, ageHours: Math.trunc(ageMs / HOUR_MS) });
    }
    return out;
  }

  /** The provider's profile, documents and items. */
  async review(id: string): Promise<Review> {
    const provider = await this.providers.get(id);
    const st = await this.states.repo.load(id);
    const nidNumber = st.nid === null ? '' : this.cipher.decrypt(st.nid.ciphertext).toString();
    return { ...st, provider, nidNumber };
  }

  /**
   * Approves or rejects one item; the decision and any level change are audited
   * through their events (PRD §6.4).
   */
  async decide(d: ItemDecision): Promise<Review> {
    const reason = d.reason.trim();
    if (!d.approve && Array.from(reason).length < 3) {
      throw new DomainError(VerificationReasons.Invalid);
    }
    const now = this.states.clock.now();
    await this.states.change(d.providerId, 'review', (st) => {
      const it = decided(itemOf(st, d.item), { now, actor: d.actor, approve: d.approve, reason });
      if (typeof it === 'string') {
        throw new DomainError(it);
      }
      st.items.set(d.item, it);
      return [decisionEvent(d, reason)];
    });
    return this.review(d.providerId);
  }
}

function decisionEvent(d: ItemDecision, reason: string): DomainEvent {
  const base = { providerId: d.providerId, item: d.item as ItemType, actorId: d.actor };
  if (d.approve) {
    const approved: DocumentApproved = { name: VerificationEvents.DocumentApproved, ...base };
    return approved;
  }
  const rejected: DocumentRejected = { name: VerificationEvents.DocumentRejected, ...base, reason };
  return rejected;
}
