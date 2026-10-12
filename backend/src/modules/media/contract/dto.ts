/** Upload purposes; each decides a file's bucket, allowed types and size limit. */
export const MediaPurpose = {
  Avatar: 'avatar',
  NidFront: 'nid_front',
  NidBack: 'nid_back',
  Selfie: 'selfie',
  PoliceClearance: 'police_clearance',
  SkillProof: 'skill_proof',
  AddressProof: 'address_proof',
  ComplaintPhoto: 'complaint_photo',
  Level2Photo: 'level2_photo',
} as const;

/** Decides a file's bucket, allowed types and size limit. */
export type MediaPurpose = (typeof MediaPurpose)[keyof typeof MediaPurpose];

/** Asks for a presigned upload URL. */
export interface UploadRequest {
  readonly ownerId: string;
  readonly purpose: MediaPurpose;
  readonly contentType: string;
  readonly sizeBytes: number;
}

/** Tells the client where and how to PUT the file. */
export interface UploadTicket {
  readonly mediaId: string;
  readonly url: string;
  readonly headers: Readonly<Record<string, string>>;
  readonly expiresAt: Date;
}

/** A stored file's metadata. */
export interface MediaObject {
  readonly id: string;
  readonly ownerId: string;
  readonly purpose: MediaPurpose;
  readonly contentType: string;
  readonly sizeBytes: number;
  readonly confirmed: boolean;
}

/** Asks to see a file. Viewer details feed the audit entry. */
export interface ViewRequest {
  readonly mediaId: string;
  readonly viewerId: string;
  readonly viewerRole: string;
}

/** A short-lived signed URL. */
export interface ViewUrl {
  readonly url: string;
  readonly expiresAt: Date;
}
