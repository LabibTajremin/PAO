import { type Text } from '../../../platform/i18n/text';
import { type Provider } from '../../provider/contract/dto';
import { type EnrolmentStatus, type EnrolmentStep } from '../../provider/contract/enrolment';

/** Reaches the provider module. */
export interface Providers {
  /** Throws `verification.provider_not_found` for an unknown provider. */
  get(id: string): Promise<Provider>;
  markStepDone(id: string, step: EnrolmentStep): Promise<EnrolmentStatus>;
  /** Throws `verification.enrolment_pending` while required steps are open. */
  markSubmitted(id: string): Promise<void>;
}

/** Checks uploads used as verification documents. */
export interface Media {
  /**
   * Checks the upload is the owner's confirmed file of an allowed purpose and spares it
   * from the orphan purge; throws `verification.bad_document` otherwise.
   */
  attach(owner: string, id: string, purposes: readonly string[]): Promise<void>;
}

/** The catalog's view of a service and the level it requires (PRD §6.1). */
export interface Service {
  readonly id: string;
  readonly name: Text;
  readonly minLevel: number;
}

/** Reads services; an unknown one throws `verification.invalid`. */
export interface Catalog {
  service(id: string): Promise<Service>;
}

/** The admin-editable verification settings. */
export interface Rules {
  readonly policeClearanceValidityMs: number;
  readonly level2CoolingOffMs: number;
}

/** Reads the rules. */
export interface Settings {
  rules(): Promise<Rules>;
}

/** Encrypts NID numbers and derives their lookup hash. */
export interface Cipher {
  encrypt(plaintext: Buffer): Buffer;
  decrypt(data: Buffer): Buffer;
  lookupHash(value: string): string;
}

/** Injection token for the {@link Providers}. */
export const PROVIDERS = Symbol('VerificationProviders');
/** Injection token for the {@link Media}. */
export const MEDIA = Symbol('VerificationMedia');
/** Injection token for the {@link Catalog}. */
export const CATALOG = Symbol('VerificationCatalog');
/** Injection token for the {@link Settings}. */
export const SETTINGS = Symbol('VerificationSettings');
/** Injection token for the {@link Cipher}. */
export const CIPHER = Symbol('VerificationCipher');
