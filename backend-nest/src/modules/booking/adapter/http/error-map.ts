import { ApiError, NOT_FOUND } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { BookingReasons as R } from '../../domain/reasons';

const conflict = (code: string, message: string) => new ApiError(409, code, message);
const unprocessable = (code: string, message: string) => new ApiError(422, code, message);

/** Booking domain reasons as API errors, equal to the Go handler's map. */
export const bookingErrors: ErrorMap = {
  [R.NotFound]: NOT_FOUND,
  [R.Invalid]: unprocessable('VALIDATION_FAILED', 'Check the booking details.'),
  [R.InvalidTransition]: conflict('BOOKING_INVALID_TRANSITION', 'The booking has moved on.'),
  [R.DeadlinePassed]: conflict('ACCEPT_DEADLINE_PASSED', 'The time to answer has passed.'),
  [R.ActiveJob]: conflict('ACTIVE_JOB_EXISTS', 'Finish your current job first.'),
  [R.CodeWrong]: unprocessable('START_CODE_INVALID', 'The start code is wrong.'),
  [R.CodeLocked]: conflict('START_CODE_LOCKED', 'Too many wrong codes. Try again later.'),
  [R.CashNotConfirmed]: unprocessable(
    'CASH_CONFIRMATION_REQUIRED',
    'Confirm that you received the cash.',
  ),
  [R.ExtrasPending]: conflict(
    'EXTRAS_PENDING',
    'The customer has not answered the extra items yet.',
  ),
  [R.NoProposal]: conflict('NO_PENDING_EXTRAS', 'There are no extra items waiting.'),
  [R.NotBookable]: conflict('PROVIDER_UNAVAILABLE', 'This provider cannot take the booking now.'),
  [R.DuplicateRequest]: conflict('DUPLICATE_BOOKING_REQUEST', 'You already asked this provider.'),
  [R.CancelNotAllowed]: conflict(
    'CANCELLATION_NOT_ALLOWED',
    'The job has started; report a problem instead.',
  ),
  [R.OutsideArea]: unprocessable(
    'OUTSIDE_SERVICE_AREA',
    'This address is outside our service area.',
  ),
  [R.ProfileRequired]: conflict('PROFILE_REQUIRED', 'Set up your profile first.'),
};
