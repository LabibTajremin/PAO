import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../../platform/errors/domain-error';
import { ConfirmUpload } from '../../app/confirm-upload';
import { CreateUpload } from '../../app/create-upload';
import { MediaObjects } from '../../app/media-objects';
import { ViewMedia } from '../../app/view-media';
import {
  type MediaObject,
  type MediaPurpose,
  type UploadRequest,
  type UploadTicket,
  type ViewRequest,
  type ViewUrl,
} from '../../contract/dto';
import { MediaErrors } from '../../contract/errors';
import { type MediaService } from '../../contract/media-service';
import { type MediaObject as StoredObject, MediaReason } from '../../domain/media';

/** Both upload refusals are one contract reason; the others already match the contract. */
function toContractError(err: unknown): unknown {
  const refused =
    err instanceof DomainError &&
    (err.reason === MediaReason.Invalid || err.reason === MediaReason.Forbidden);
  return refused ? new DomainError(MediaErrors.UploadInvalid, { cause: err }) : err;
}

async function translated<T>(work: Promise<T>): Promise<T> {
  try {
    return await work;
  } catch (err) {
    throw toContractError(err);
  }
}

function toContract(o: StoredObject): MediaObject {
  return {
    id: o.id,
    ownerId: o.ownerId,
    purpose: o.purpose as MediaPurpose,
    contentType: o.contentType,
    sizeBytes: o.sizeBytes,
    confirmed: o.confirmed,
  };
}

/** The media contract for other modules in the process. */
@Injectable()
export class InprocMediaService implements MediaService {
  constructor(
    @Inject(CreateUpload) private readonly uploads: CreateUpload,
    @Inject(ConfirmUpload) private readonly confirmations: ConfirmUpload,
    @Inject(ViewMedia) private readonly views: ViewMedia,
    @Inject(MediaObjects) private readonly objects: MediaObjects,
  ) {}

  /** Uploads made by other modules, such as Level 2 visit photos recorded by verifiers. */
  createUploadUrl(req: UploadRequest): Promise<UploadTicket> {
    return translated(this.uploads.create(req.ownerId, 'admin', req));
  }

  async confirmUpload(ownerId: string, mediaId: string): Promise<MediaObject> {
    return toContract(await translated(this.confirmations.confirm(ownerId, mediaId)));
  }

  async getObject(mediaId: string): Promise<MediaObject> {
    return toContract(await translated(this.objects.get(mediaId)));
  }

  markAttached(mediaId: string): Promise<void> {
    return translated(this.objects.markAttached(mediaId));
  }

  getViewUrl(req: ViewRequest): Promise<ViewUrl> {
    return translated(this.views.viewUrl(req.mediaId, { id: req.viewerId, role: req.viewerRole }));
  }

  delete(mediaId: string): Promise<void> {
    return translated(this.objects.delete(mediaId));
  }

  async deleteOwnerFiles(ownerId: string): Promise<void> {
    await this.objects.deleteOwned(ownerId, true);
  }
}
