import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { objectKey, type Uploader, uploadRefusal } from '../domain/media';
import {
  FILE_STORE,
  type FileStore,
  MEDIA_REPOSITORY,
  type MediaRepository,
} from '../port/media-ports';

/** How long a presigned upload URL works. */
export const UPLOAD_URL_TTL_MS = 15 * 60_000;

/** A file the owner wants to upload. */
export interface UploadIntent {
  readonly purpose: string;
  readonly contentType: string;
  readonly sizeBytes: number;
}

/** Where and how the client PUTs the file. */
export interface Ticket {
  readonly mediaId: string;
  readonly url: string;
  readonly headers: Readonly<Record<string, string>>;
  readonly expiresAt: Date;
}

/** Records a pending upload and hands out a presigned PUT URL for it. */
@Injectable()
export class CreateUpload {
  constructor(
    @Inject(MEDIA_REPOSITORY) private readonly repo: MediaRepository,
    @Inject(FILE_STORE) private readonly files: FileStore,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Checks the file against its purpose's rules for this kind of uploader first. */
  async create(ownerId: string, uploader: Uploader, file: UploadIntent): Promise<Ticket> {
    const refusal = uploadRefusal(uploader, file);
    if (refusal !== undefined) {
      throw new DomainError(refusal);
    }
    const id = this.ids.newId();
    const object = {
      ...file,
      id,
      ownerId,
      bucket: this.files.uploadBucket,
      key: objectKey(file.purpose, ownerId, id),
      confirmed: false,
      attached: false,
      createdAt: this.clock.now(),
    };
    await this.repo.create(object);
    const signed = await this.files.presignPut({
      bucket: object.bucket,
      key: object.key,
      contentType: file.contentType,
      size: file.sizeBytes,
      ttlSeconds: UPLOAD_URL_TTL_MS / 1000,
    });
    return {
      mediaId: id,
      url: signed.url,
      headers: signed.headers,
      expiresAt: new Date(object.createdAt.getTime() + UPLOAD_URL_TTL_MS),
    };
  }
}
