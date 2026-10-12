import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type ObjectInfo, ObjectNotFoundError } from '../../../platform/storage/object-store';
import { type MediaObject, MediaReason } from '../domain/media';
import {
  FILE_STORE,
  type FileStore,
  MEDIA_REPOSITORY,
  type MediaRepository,
} from '../port/media-ports';

/** Checks that an owner's file arrived with the declared type and size. */
@Injectable()
export class ConfirmUpload {
  constructor(
    @Inject(MEDIA_REPOSITORY) private readonly repo: MediaRepository,
    @Inject(FILE_STORE) private readonly files: FileStore,
  ) {}

  /**
   * Marks the object confirmed; confirming twice is harmless. A file that differs from
   * the request is deleted, so the owner uploads it again.
   */
  async confirm(ownerId: string, id: string): Promise<MediaObject> {
    const object = await this.repo.get(id);
    if (object.ownerId !== ownerId) {
      throw new DomainError(MediaReason.NotFound);
    }
    if (object.confirmed) {
      return object;
    }
    const stored = await this.stored(object);
    if (stored.size !== object.sizeBytes || stored.contentType !== object.contentType) {
      const deleted = await this.files
        .delete(object.bucket, object.key)
        .catch((err: unknown) => err);
      throw new DomainError(MediaReason.NotUploaded, { cause: deleted });
    }
    await this.repo.markConfirmed(id);
    return { ...object, confirmed: true };
  }

  private async stored(object: MediaObject): Promise<ObjectInfo> {
    try {
      return await this.files.head(object.bucket, object.key);
    } catch (err) {
      throw err instanceof ObjectNotFoundError
        ? new DomainError(MediaReason.NotUploaded, { cause: err })
        : err;
    }
  }
}
