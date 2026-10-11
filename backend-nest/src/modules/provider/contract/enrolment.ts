/**
 * Enrolment steps in wizard order (M05–M13). The provider module saves the profile
 * steps; the document steps (NID, selfie, police clearance, skill proof) are saved by
 * verification, which reports them done through `markStepDone`.
 */
export const EnrolmentStep = {
  Personal: 'personal',
  Services: 'services',
  Area: 'area',
  Nid: 'nid',
  Selfie: 'selfie',
  PoliceClearance: 'police_clearance',
  SkillProof: 'skill_proof',
  EmergencyContact: 'emergency_contact',
  CodeOfConduct: 'code_of_conduct',
} as const;

/** Names a wizard step (M05–M13). */
export type EnrolmentStep = (typeof EnrolmentStep)[keyof typeof EnrolmentStep];

/** One wizard step's progress. */
export interface StepStatus {
  readonly step: EnrolmentStep;
  readonly done: boolean;
  readonly required: boolean;
}

/** The wizard progress (M05–M13); saved steps survive app restarts. */
export interface EnrolmentStatus {
  readonly steps: readonly StepStatus[];
  readonly complete: boolean;
  readonly submitted: boolean;
}
