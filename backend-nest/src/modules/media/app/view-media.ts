import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { AUDIT_SERVICE, type AuditService } from '../../audit/contract';
import { type MediaObject, MediaReason, ruleFor } from '../domain/media';
import {
  FILE_STORE,
  type FileStore,
  MEDIA_REPOSITORY,
  type MediaRepository,
} from '../port/media-ports';

/** How long a view URL works (PRD §6.6). */
export const VIEW_URL_TTL_MS = 5 * 60_000;

/** Who asks to see a file; their role goes into the audit entry. */
export interface Viewer {
  readonly id: string;
  readonly role: string;
}

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
    @Inject(AUDIT_SERVICE) private readonly audit: AuditService,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
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
      await this.recordView(object, viewer);
    }
    const url = await this.files.presignGet(object.bucket, object.key, VIEW_URL_TTL_MS / 1000);
    return { url, expiresAt: new Date(this.clock.now().getTime() + VIEW_URL_TTL_MS) };
  }

  private async recordView(object: MediaObject, viewer: Viewer): Promise<void> {
    try {
      await this.audit.record({
        id: this.ids.newId(),
        at: this.clock.now(),
        actorId: viewer.id,
        actorRole: viewer.role,
        action: 'media.document_viewed',
        subjectType: 'media',
        subjectId: object.id,
        reason: '',
        before: null,
        after: { purpose: object.purpose, owner: object.ownerId },
      });
    } catch (cause) {
      throw new Error('audit document view', { cause });
    }
  }
}
