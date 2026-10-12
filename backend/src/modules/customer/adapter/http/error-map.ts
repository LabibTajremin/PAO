import { ApiError, NOT_FOUND } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { CustomerReasons } from '../../app/errors';

/** Customer domain reasons as API errors, equal to the Go handler's map. */
export const customerErrors: ErrorMap = {
  [CustomerReasons.NotFound]: new ApiError(404, 'PROFILE_NOT_FOUND', 'Set up your profile first.'),
  [CustomerReasons.AddressNotFound]: NOT_FOUND,
  [CustomerReasons.Invalid]: new ApiError(
    422,
    'VALIDATION_FAILED',
    'Check the details and try again.',
  ),
  [CustomerReasons.InvalidPhoto]: new ApiError(422, 'UPLOAD_INVALID', 'Upload the photo again.'),
  [CustomerReasons.OutsideCountry]: new ApiError(
    422,
    'OUTSIDE_SERVICE_AREA',
    'Place the pin inside Bangladesh.',
  ),
  [CustomerReasons.AddressLimit]: new ApiError(
    409,
    'ADDRESS_LIMIT_REACHED',
    'You can save up to 10 addresses. Delete one first.',
  ),
  [CustomerReasons.ProfileRequired]: new ApiError(
    409,
    'PROFILE_REQUIRED',
    'Set up your profile first.',
  ),
};
