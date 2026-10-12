import { ApiError, NOT_FOUND } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { VerificationReasons } from '../../domain/reasons';

/** Verification domain reasons as API errors, equal to the Go handler's map. */
export const verificationErrors: ErrorMap = {
  [VerificationReasons.NotFound]: NOT_FOUND,
  [VerificationReasons.Invalid]: new ApiError(
    422,
    'VALIDATION_FAILED',
    'Check the details and try again.',
  ),
  [VerificationReasons.BadDocument]: new ApiError(
    422,
    'UPLOAD_INVALID',
    'Upload the document again.',
  ),
  [VerificationReasons.ClearanceTooOld]: new ApiError(
    422,
    'CLEARANCE_TOO_OLD',
    'The police clearance must be issued within the last 12 months.',
  ),
  [VerificationReasons.NidBlocked]: new ApiError(
    403,
    'NID_BLOCKED',
    'This NID cannot be used to register.',
  ),
  [VerificationReasons.NotPending]: new ApiError(
    409,
    'ITEM_NOT_PENDING',
    'This item is not waiting for a decision.',
  ),
  [VerificationReasons.EnrolmentPending]: new ApiError(
    409,
    'ENROLMENT_INCOMPLETE',
    'Finish every required step first.',
  ),
  [VerificationReasons.NotEligible]: new ApiError(
    409,
    'LEVEL2_NOT_ELIGIBLE',
    'Level 2 needs a Level 1 provider.',
  ),
  [VerificationReasons.CoolingOff]: new ApiError(
    409,
    'LEVEL2_COOLING_OFF',
    'The provider must wait before retrying.',
  ),
  [VerificationReasons.SessionClosed]: new ApiError(
    409,
    'SESSION_CLOSED',
    'This session already has a result.',
  ),
};
