// The upload rules per purpose (P04 task 4, PRD §6.6).

/**
 * Reasons of the `DomainError`s the media use cases raise. `not_found` and
 * `not_uploaded` are also the contract's reasons.
 */
export const MediaReason = {
  /** The file type or size breaks the purpose's rule. */
  Invalid: 'media.invalid',
  /** This app may not upload files of that purpose. */
  Forbidden: 'media.forbidden',
  /** No such object, or not the caller's. */
  NotFound: 'media.not_found',
  /** The file is missing from storage or differs from the request. */
  NotUploaded: 'media.not_uploaded',
} as const;

/** What a purpose accepts. */
export interface Rule {
  readonly contentTypes: readonly string[];
  readonly maxBytes: number;
  /**
   * Verification documents: every view is audited and they never reach customer APIs.
   */
  readonly sensitive: boolean;
}

const MB = 1 << 20;
const IMAGES = ['image/jpeg', 'image/png'];
const DOCUMENTS = ['image/jpeg', 'image/png', 'application/pdf'];
const image = (maxBytes: number, sensitive = false): Rule => ({
  contentTypes: IMAGES,
  maxBytes,
  sensitive,
});
const document: Rule = { contentTypes: DOCUMENTS, maxBytes: 5 * MB, sensitive: true };

const RULES: Readonly<Record<string, Rule>> = {
  avatar: image(2 * MB),
  complaint_photo: image(5 * MB),
  nid_front: image(5 * MB, true),
  nid_back: image(5 * MB, true),
  selfie: image(5 * MB, true),
  police_clearance: document,
  skill_proof: document,
  address_proof: document,
  level2_photo: image(5 * MB, true),
};

/** Who uploads: the customer app, the provider app or an admin (through other modules). */
export type Uploader = 'customer' | 'provider' | 'admin';

const UPLOADS: Readonly<Record<Uploader, readonly string[]>> = {
  customer: ['avatar', 'complaint_photo'],
  provider: [
    'avatar',
    'complaint_photo',
    'nid_front',
    'nid_back',
    'selfie',
    'police_clearance',
    'skill_proof',
    'address_proof',
  ],
  admin: ['level2_photo'],
};

/** The rule of a purpose, if it is one. */
export function ruleFor(purpose: string): Rule | undefined {
  return Object.hasOwn(RULES, purpose) ? RULES[purpose] : undefined;
}

/** Why an upload is refused, or undefined when it may go ahead. */
export function uploadRefusal(
  uploader: Uploader,
  upload: { purpose: string; contentType: string; sizeBytes: number },
): string | undefined {
  const rule = ruleFor(upload.purpose);
  if (!rule || !UPLOADS[uploader].includes(upload.purpose)) {
    return MediaReason.Forbidden;
  }
  const fits = upload.sizeBytes >= 1 && upload.sizeBytes <= rule.maxBytes;
  return rule.contentTypes.includes(upload.contentType) && fits ? undefined : MediaReason.Invalid;
}

/** A stored file's record. */
export interface MediaObject {
  readonly id: string;
  readonly ownerId: string;
  readonly purpose: string;
  readonly contentType: string;
  readonly sizeBytes: number;
  readonly bucket: string;
  readonly key: string;
  readonly confirmed: boolean;
  readonly attached: boolean;
  readonly createdAt: Date;
}

/** Places files by purpose and owner, so retention jobs can work per owner. */
export function objectKey(purpose: string, ownerId: string, id: string): string {
  return `${purpose}/${ownerId}/${id}`;
}
