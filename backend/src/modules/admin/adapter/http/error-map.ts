import { ApiError, NOT_FOUND, VALIDATION_FAILED } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { IdentityErrors } from '../../../identity/contract/errors';
import { AdminErrors } from '../../app/errors';

/** Admin domain reasons as API errors, equal to the Go handler's map. */
export const adminErrors: ErrorMap = {
  [AdminErrors.SettingNotFound]: NOT_FOUND,
  [AdminErrors.SettingInvalid]: new ApiError(
    422,
    'SETTING_INVALID',
    'This value does not fit the setting.',
  ),
  [AdminErrors.ComplaintNotFound]: NOT_FOUND,
  [AdminErrors.BookingNotFound]: NOT_FOUND,
  [AdminErrors.ComplaintInvalid]: VALIDATION_FAILED,
  [AdminErrors.PhotoInvalid]: new ApiError(
    422,
    'UPLOAD_INVALID',
    'Attach confirmed complaint photos only.',
  ),
  [AdminErrors.AssigneeInvalid]: new ApiError(
    422,
    'VALIDATION_FAILED',
    'This admin cannot work complaints.',
  ),
  [AdminErrors.AlreadyResolved]: new ApiError(
    409,
    'COMPLAINT_INVALID_TRANSITION',
    'This complaint is already resolved.',
  ),
  [AdminErrors.PersonNotFound]: NOT_FOUND,
  [IdentityErrors.StatusInvalid]: new ApiError(
    409,
    'CONFLICT',
    'The account already has this status.',
  ),
};
