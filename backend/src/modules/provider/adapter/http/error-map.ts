import { ApiError, NOT_FOUND } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { ProviderReasons } from '../../domain/reasons';

/** Provider domain reasons as API errors, equal to the Go handler's map. */
export const providerErrors: ErrorMap = {
  [ProviderReasons.NotFound]: NOT_FOUND,
  [ProviderReasons.Invalid]: new ApiError(
    422,
    'VALIDATION_FAILED',
    'Check the details and try again.',
  ),
  [ProviderReasons.TooYoung]: new ApiError(
    422,
    'AGE_REQUIREMENT',
    'Providers must be at least 18 years old.',
  ),
  [ProviderReasons.UnknownService]: new ApiError(
    422,
    'SERVICE_UNAVAILABLE',
    'One of these services is not offered.',
  ),
  [ProviderReasons.InvalidPhoto]: new ApiError(422, 'UPLOAD_INVALID', 'Upload the photo again.'),
  [ProviderReasons.CodeRejected]: new ApiError(422, 'OTP_INVALID', 'The code is wrong or expired.'),
  [ProviderReasons.CodeRateLimited]: new ApiError(
    429,
    'RATE_LIMITED',
    'Too many codes. Try again later.',
  ),
  [ProviderReasons.ContactUnproven]: new ApiError(
    409,
    'EMERGENCY_CONTACT_MISSING',
    'Add the emergency contact first.',
  ),
  [ProviderReasons.NotVerified]: new ApiError(
    403,
    'NOT_VERIFIED',
    'You can go online after verification.',
  ),
  [ProviderReasons.NoServiceArea]: new ApiError(
    409,
    'SERVICE_AREA_MISSING',
    'Choose your services and area first.',
  ),
  [ProviderReasons.Offline]: new ApiError(409, 'OFFLINE', 'Go online first.'),
};
