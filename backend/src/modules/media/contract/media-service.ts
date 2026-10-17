import {
  type MediaObject,
  type UploadRequest,
  type UploadTicket,
  type ViewRequest,
  type ViewUrl,
} from './dto';

/** What other modules may ask of the media module (PRD §9.3 rule 1). */
export interface MediaService {
  /**
   * Validates the request against the purpose's rules and returns a presigned PUT URL
   * (documents: JPEG/PNG/PDF ≤ 5 MB; avatars: JPEG/PNG ≤ 2 MB).
   */
  createUploadUrl(request: UploadRequest): Promise<UploadTicket>;
  /** Checks that the object exists and matches the request. */
  confirmUpload(ownerId: string, mediaId: string): Promise<MediaObject>;
  /** Returns metadata, so callers can check owner and purpose before attaching. */
  getObject(mediaId: string): Promise<MediaObject>;
  /** Records that a record references the object, sparing it from the orphan purge. */
  markAttached(mediaId: string): Promise<void>;
  /**
   * Returns a 5-minute signed GET URL. Viewing a verification document writes an audit
   * entry (PRD §6.6).
   */
  getViewUrl(request: ViewRequest): Promise<ViewUrl>;
  /** Removes the object from storage and its record. */
  delete(mediaId: string): Promise<void>;
  /** Removes every file the account uploaded, documents included (retention purge). */
  deleteOwnerFiles(ownerId: string): Promise<void>;
}

/** Injection token for the {@link MediaService}. */
export const MEDIA_SERVICE = Symbol('MediaService');
