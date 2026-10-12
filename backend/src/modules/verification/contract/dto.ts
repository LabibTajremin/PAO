/** The Level 1 requirements from PRD §6.2. */
export const ItemType = {
  Nid: 'nid',
  Selfie: 'selfie',
  PoliceClearance: 'police_clearance',
  Address: 'address',
  EmergencyContact: 'emergency_contact',
  SkillProof: 'skill_proof',
  ServiceArea: 'service_area',
  CodeOfConduct: 'code_of_conduct',
} as const;

/** One Level 1 requirement from PRD §6.2. */
export type ItemType = (typeof ItemType)[keyof typeof ItemType];

/** One verification requirement as admins see it beside the provider record. */
export interface Item {
  readonly type: ItemType;
  readonly status: string;
  readonly reason: string;
  readonly required: boolean;
  readonly decidedAt: Date | null;
  readonly expiresAt: Date | null;
}
