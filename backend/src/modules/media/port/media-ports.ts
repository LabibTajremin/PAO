import { type ObjectInfo, type PresignedUpload } from '../../../platform/storage/object-store';
import { type MediaObject } from '../domain/media';

/** Stores object records (`media.objects`). */
export interface MediaRepository {
  create(o: MediaObject): Promise<void>;
  /** Throws `media.not_found`. */
  get(id: string): Promise<MediaObject>;
  markConfirmed(id: string): Promise<void>;
  /** Throws `media.not_found`. */
  markAttached(id: string): Promise<void>;
  delete(id: string): Promise<void>;
  /** Objects never attached and created before `createdBefore`, oldest first. */
  orphans(createdBefore: Date): Promise<MediaObject[]>;
}

/** Injection token for the {@link MediaRepository}. */
export const MEDIA_REPOSITORY = Symbol('MediaRepository');

/** The object store (platform `ObjectStore`) with the private bucket uploads go to. */
export interface FileStore {
  readonly uploadBucket: string;
  presignPut(req: {
    bucket: string;
    key: string;
    contentType: string;
    size: number;
    ttlSeconds: number;
  }): Promise<PresignedUpload>;
  presignGet(bucket: string, key: string, ttlSeconds: number): Promise<string>;
  /** Throws the platform's `ObjectNotFoundError` for a missing object. */
  head(bucket: string, key: string): Promise<ObjectInfo>;
  delete(bucket: string, key: string): Promise<void>;
}

/** Injection token for the {@link FileStore}. */
export const FILE_STORE = Symbol('MediaFileStore');
