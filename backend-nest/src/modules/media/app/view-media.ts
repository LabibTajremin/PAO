import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { MediaReason, ruleFor } from '../domain/media';
import {
  FILE_STORE,
  type FileStore,
  MEDIA_REPOSITORY,
  type MediaRepository,
} from '../port/media-ports';
import { DocumentViewAudit, type Viewer } from './document-view-audit';

/** How long a view URL works (PRD §6.6). */
export const VIEW_URL_TTL_MS = 5 * 60_000;

/** A short-lived signed URL. */
export interface ViewUrl {
  readonly url: string;
  readonly expiresAt: Date;
}

/** Hands out short-lived download URLs for confirmed files. */
@Injectable()
export class ViewMedia {
  constructor(
    @Inject(MEDIA_REPOSITORY) private readonly repo: MediaRepository,
    @Inject(FILE_STORE) private readonly files: FileStore,
    @Inject(DocumentViewAudit) private readonly audit: DocumentViewAudit,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /**
   * A 5-minute signed URL. Viewing a verification document is audited first, so no
   * view goes unrecorded (PRD §6.6).
   */
  async viewUrl(id: string, viewer: Viewer): Promise<ViewUrl> {
    const object = await this.repo.get(id);
    if (!object.confirmed) {
      throw new DomainError(MediaReason.NotFound);
    }
    if (ruleFor(object.purpose)?.sensitive) {
      await this.audit.record(object, viewer);
    }
    const url = await this.files.presignGet(object.bucket, object.key, VIEW_URL_TTL_MS / 1000);
    return { url, expiresAt: new Date(this.clock.now().getTime() + VIEW_URL_TTL_MS) };
  }
}
