/**
 * `DomainError` reasons the media module raises through its contract; other modules
 * compare against these with `isDomainError`.
 */
export const MediaErrors = {
  /** The upload does not meet the purpose's rules. */
  UploadInvalid: 'media.upload_invalid',
  /** No media record has the id. */
  NotFound: 'media.not_found',
  /** The stored object is missing or differs from the request. */
  NotUploaded: 'media.not_uploaded',
} as const;

/** A reason from {@link MediaErrors}. */
export type MediaErrorReason = (typeof MediaErrors)[keyof typeof MediaErrors];
