import { ApiError, NOT_FOUND } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { MediaReason } from '../../domain/media';

/** Media failures as API errors, with the Go API's codes and messages. */
export const mediaErrors: ErrorMap = {
  [MediaReason.Invalid]: new ApiError(
    422,
    'UPLOAD_INVALID',
    'This file type or size is not allowed here.',
  ),
  [MediaReason.Forbidden]: new ApiError(
    422,
    'UPLOAD_INVALID',
    'This app cannot upload that kind of file.',
  ),
  [MediaReason.NotFound]: NOT_FOUND,
  [MediaReason.NotUploaded]: new ApiError(
    409,
    'UPLOAD_NOT_FOUND',
    'The file did not arrive or does not match. Upload it again.',
  ),
};
