import { Inject, Injectable } from '@nestjs/common';
import { type EnrolmentStatus, type EnrolmentStep } from '../../provider/contract/enrolment';
import { itemOf, type State } from '../domain/state';
import { submitted } from '../domain/items';
import { MEDIA, type Media, PROVIDERS, type Providers } from '../port/peers';
import { States } from './states';

/** One file of a document step. */
export interface Upload {
  readonly kind: string;
  readonly mediaId: string;
}

/** A document step as the provider sends it. */
export interface Submission {
  readonly item: string;
  readonly files: readonly Upload[];
  readonly fields: Readonly<Record<string, string>>;
  readonly expiresAt: Date | null;
  /** Further edits to the state, e.g. the new NID. */
  readonly extra?: (st: State) => void;
}

/** Puts document steps into review. */
@Injectable()
export class Submissions {
  constructor(
    private readonly states: States,
    @Inject(PROVIDERS) private readonly providers: Providers,
    @Inject(MEDIA) private readonly media: Media,
  ) {}

  /** Attaches the uploads, puts the item into review and marks the wizard step. */
  async submit(id: string, s: Submission): Promise<EnrolmentStatus> {
    for (const f of s.files) {
      await this.media.attach(id, f.mediaId, [f.kind]);
    }
    const now = this.states.clock.now();
    await this.states.change(id, 'resubmitted', (st) => {
      s.extra?.(st);
      st.items.set(s.item, submitted(itemOf(st, s.item), now, s.fields, s.expiresAt));
      for (const f of s.files) {
        const doc = { id: this.states.ids.newId(), itemType: s.item, ...f, createdAt: now };
        st.newDocuments.push(doc);
      }
      return [];
    });
    return this.providers.markStepDone(id, s.item as EnrolmentStep);
  }
}
