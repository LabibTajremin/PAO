import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { contactValid, normalizePhone, type Progress, withoutStep } from '../domain/enrolment';
import { type EmergencyContact } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import { ACCOUNTS, type Accounts } from '../port/peers';
import { Profiles } from './profiles';

/** The guarantor step, proven by a one-time code sent to their phone (PRD §6.2 item 6). */
@Injectable()
export class SaveEmergencyContact {
  constructor(
    private readonly profiles: Profiles,
    @Inject(ACCOUNTS) private readonly accounts: Accounts,
  ) {}

  /**
   * Stores the guarantor and sends them a code; the step is done only after
   * {@link verify}. A failed send leaves the old contact in place.
   */
  save(id: string, input: Omit<EmergencyContact, 'verifiedAt'>): Promise<Progress> {
    const phone = normalizePhone(input.phone);
    if (phone === undefined) {
      return Promise.reject(new DomainError(ProviderReasons.Invalid));
    }
    const contact = { ...input, phone, verifiedAt: null };
    return this.profiles.update(id, null, async (p) => {
      if (!contactValid(contact, p.phone)) {
        throw new DomainError(ProviderReasons.Invalid);
      }
      await this.accounts.sendContactCode(phone);
      return { ...p, emergency: contact, stepsDone: withoutStep(p.stepsDone, 'emergency_contact') };
    });
  }

  /** Checks the code sent to the guarantor. */
  verify(id: string, code: string): Promise<Progress> {
    return this.profiles.update(id, 'emergency_contact', async (p) => {
      if (p.emergency.phone === '') {
        throw new DomainError(ProviderReasons.ContactUnproven);
      }
      await this.accounts.checkContactCode(p.emergency.phone, code);
      return { ...p, emergency: { ...p.emergency, verifiedAt: this.profiles.clock.now() } };
    });
  }
}
