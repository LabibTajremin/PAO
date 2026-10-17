import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { AUDIT_SERVICE, type AuditService } from '../../audit/contract';
import { type MediaObject } from '../domain/media';

/** Who asks to see a file; their role goes into the audit entry. */
export interface Viewer {
  readonly id: string;
  readonly role: string;
}

/** Writes the audit entry for a view of a verification document (PRD §6.6). */
@Injectable()
export class DocumentViewAudit {
  constructor(
    @Inject(AUDIT_SERVICE) private readonly audit: AuditService,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Records that `viewer` looked at `object`. */
  async record(object: MediaObject, viewer: Viewer): Promise<void> {
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
