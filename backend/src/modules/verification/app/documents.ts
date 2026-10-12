import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type EnrolmentStatus } from '../../provider/contract/enrolment';
import { clearanceExpiry, dhakaDate, validNid } from '../domain/items';
import { VerificationReasons } from '../domain/reasons';
import { CIPHER, type Cipher, SETTINGS, type Settings } from '../port/peers';
import { States } from './states';
import { Submissions } from './submissions';

/** The document steps of the enrolment wizard (M08–M11). */
@Injectable()
export class SaveDocuments {
  constructor(
    private readonly submissions: Submissions,
    private readonly states: States,
    @Inject(SETTINGS) private readonly settings: Settings,
    @Inject(CIPHER) private readonly cipher: Cipher,
  ) {}

  /**
   * Stores the encrypted NID number with both sides of the card (M08). A number on the
   * block list cannot enrol again (PRD §6.4).
   */
  async saveNid(id: string, number: string, front: string, back: string): Promise<EnrolmentStatus> {
    if (!validNid(number)) {
      throw new DomainError(VerificationReasons.Invalid);
    }
    const hash = this.cipher.lookupHash(number);
    if (await this.states.repo.nidBlocked(hash)) {
      throw new DomainError(VerificationReasons.NidBlocked);
    }
    const ciphertext = this.cipher.encrypt(Buffer.from(number));
    return this.submissions.submit(id, {
      item: 'nid',
      files: [
        { kind: 'nid_front', mediaId: front },
        { kind: 'nid_back', mediaId: back },
      ],
      fields: {},
      expiresAt: null,
      extra: (st) => {
        st.nid = { ciphertext, hash };
        st.nidChanged = true;
      },
    });
  }

  /** Stores the live selfie (M09); a verifier compares it with the NID photo (D10). */
  saveSelfie(id: string, mediaId: string): Promise<EnrolmentStatus> {
    return this.submissions.submit(id, {
      item: 'selfie',
      files: [{ kind: 'selfie', mediaId }],
      fields: {},
      expiresAt: null,
    });
  }

  /**
   * Stores the certificate; it must be under the validity period old and expires that
   * long after its issue date (PRD §6.2 item 4, §6.4).
   */
  async savePoliceClearance(id: string, mediaId: string, issued: Date): Promise<EnrolmentStatus> {
    const rules = await this.settings.rules();
    // The issue date is a Dhaka calendar date, so "today" must be one too; UTC would
    // reject a certificate issued today for the six hours after 18:00 UTC.
    const today = dhakaDate(this.states.clock.now());
    const expiresAt = clearanceExpiry(issued, today, rules.policeClearanceValidityMs);
    if (expiresAt === undefined) {
      throw new DomainError(VerificationReasons.ClearanceTooOld);
    }
    return this.submissions.submit(id, {
      item: 'police_clearance',
      files: [{ kind: 'police_clearance', mediaId }],
      fields: { issueDate: issued.toISOString().slice(0, 10) },
      expiresAt,
    });
  }

  /** Stores optional certificates or work photos (PRD §6.2 item 7). */
  saveSkillProof(id: string, mediaIds: readonly string[]): Promise<EnrolmentStatus> {
    if (mediaIds.length === 0 || mediaIds.length > 10) {
      return Promise.reject(new DomainError(VerificationReasons.Invalid));
    }
    return this.submissions.submit(id, {
      item: 'skill_proof',
      files: mediaIds.map((mediaId) => ({ kind: 'skill_proof', mediaId })),
      fields: {},
      expiresAt: null,
    });
  }
}
