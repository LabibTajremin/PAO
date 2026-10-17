import { Controller, Get, Inject, Query } from '@nestjs/common';
import { decodeCursor, encodeCursor, pageSize } from '../../../../platform/http/cursor';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { AuditLog } from '../../app/audit-log';
import { type Entry } from '../../domain/entry';

type Schemas = components['schemas'];
type ListQuery = NonNullable<operations['listAuditEntries']['parameters']['query']>;

/** The API shape of an entry; empty role, reason and states are left out. */
function entryView(e: Entry): Schemas['AuditEntry'] {
  return {
    id: e.id,
    at: e.at.toISOString(),
    ...(e.actorId === null ? {} : { actorId: e.actorId }),
    ...(e.actorRole === '' ? {} : { actorRole: e.actorRole }),
    action: e.action,
    subjectType: e.subjectType,
    subjectId: e.subjectId,
    ...(e.reason === '' ? {} : { reason: e.reason }),
    ...(e.before === null ? {} : { before: { ...e.before } }),
    ...(e.after === null ? {} : { after: { ...e.after } }),
  };
}

/** The audit log viewer (A-08). */
@Controller('v1/admin/audit')
export class AuditController {
  constructor(@Inject(AuditLog) private readonly log: AuditLog) {}

  @Get()
  @RequirePermission('audit:read')
  async listAuditEntries(@Query() query: ListQuery): Promise<Schemas['AuditList']> {
    const cursor = decodeCursor(query.cursor);
    const limit = pageSize(query.limit);
    const entries = await this.log.list(
      {
        actorId: query.actorId,
        action: query.action,
        subjectId: query.subjectId,
        from: query.from === undefined ? undefined : new Date(query.from),
        to: query.to === undefined ? undefined : new Date(query.to),
      },
      {
        after: cursor && { at: new Date(cursor.createdAt), id: cursor.id },
        limit: limit + 1,
      },
    );
    const items = entries.slice(0, limit);
    const last = items.at(-1);
    const more = entries.length > limit && last !== undefined;
    return {
      items: items.map(entryView),
      ...(more ? { nextCursor: encodeCursor({ createdAt: last.at, id: last.id }) } : {}),
    };
  }
}
