import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { isDomainError } from '../../../../platform/errors/domain-error';
import { MediaErrors } from '../../../media/contract/errors';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { type Files } from '../../port/closures';

/** Deletes verification files through the media contract. */
@Injectable()
export class MediaFiles implements Files {
  private readonly media: LazyContract<MediaService>;

  constructor(ref: ModuleRef) {
    this.media = new LazyContract(ref, MEDIA_SERVICE);
  }

  deleteOwned(ownerId: string): Promise<void> {
    return this.media.get().deleteOwnerFiles(ownerId);
  }

  async delete(mediaId: string): Promise<void> {
    try {
      await this.media.get().delete(mediaId);
    } catch (err) {
      if (!isDomainError(err, MediaErrors.NotFound)) {
        throw err;
      }
    }
  }
}
