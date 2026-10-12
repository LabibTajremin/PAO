import { Inject, Injectable } from '@nestjs/common';
import { type AuditEntry, type AuditService } from '../../contract';
import { AuditLog } from '../../app/audit-log';

/** The audit contract for other modules in the process. */
@Injectable()
export class InProcessAuditService implements AuditService {
  constructor(@Inject(AuditLog) private readonly log: AuditLog) {}

  /** Appends `entry`; its id is ignored and a fresh one assigned. */
  record(entry: AuditEntry): Promise<void> {
    return this.log.record(entry);
  }

  async listForSubject(subjectType: string, subjectId: string, limit: number) {
    const entries = await this.log.list({ subjectType, subjectId }, { limit });
    return entries.map(({ eventId: _eventId, ...e }) => e);
  }
}
