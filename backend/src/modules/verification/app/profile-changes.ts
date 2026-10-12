import { Inject, Injectable } from '@nestjs/common';
import { EnrolmentStep } from '../../provider/contract/enrolment';
import { ItemStatus, submitted } from '../domain/items';
import { itemOf } from '../domain/state';
import { PROVIDERS, type Providers } from '../port/peers';
import { States } from './states';

/** The item each saved profile step puts back into review. */
const STEP_ITEMS: Readonly<Record<string, string>> = {
  [EnrolmentStep.Personal]: 'address',
  [EnrolmentStep.Services]: 'service_area',
  [EnrolmentStep.Area]: 'service_area',
  [EnrolmentStep.EmergencyContact]: 'emergency_contact',
  [EnrolmentStep.CodeOfConduct]: 'code_of_conduct',
};

/** Reacts to profile and account changes made elsewhere (PRD §6.4). */
@Injectable()
export class ProfileChanges {
  constructor(
    private readonly states: States,
    @Inject(PROVIDERS) private readonly providers: Providers,
  ) {}

  /**
   * Puts the item matching a saved profile step into review, and keeps the service list
   * used by the queue filter current.
   */
  async onStepSaved(id: string, step: string): Promise<void> {
    const item = STEP_ITEMS[step];
    if (item === undefined) {
      return;
    }
    const p = await this.providers.get(id);
    const now = this.states.clock.now();
    await this.states.change(id, 'resubmitted', (st) => {
      st.items.set(item, submitted(itemOf(st, item), now, {}, null));
      st.serviceIds = [...p.serviceIds];
      // A changed name or birth date must match the NID again (PRD §6.4).
      const nid = itemOf(st, 'nid');
      if (step === EnrolmentStep.Personal && nid.status !== ItemStatus.Missing) {
        st.items.set('nid', submitted(nid, now, nid.fields, null));
      }
      return [];
    });
  }

  /**
   * Blocks suspended and banned providers; a ban also blocks their NID from enrolling
   * again.
   */
  async onAccountStatus(id: string, status: string): Promise<void> {
    await this.states.repo.change(id, (st) => {
      st.blocked = status !== 'active';
      return [];
    });
    if (status === 'banned') {
      await this.states.repo.blockNid(id, 'account banned');
    }
  }
}
