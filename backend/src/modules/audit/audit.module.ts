import { Global, Module } from '@nestjs/common';
import { AuditController } from './adapter/http/audit.controller';
import { InProcessAuditService } from './adapter/inproc/audit-service';
import { PostgresEntryRepository } from './adapter/postgres/postgres-entry-repository';
import { AuditSubscribers } from './adapter/worker/audit-subscribers';
import { AuditLog } from './app/audit-log';
import { AUDIT_SERVICE } from './contract';
import { ENTRY_REPOSITORY } from './port/entry-repository';

/**
 * The append-only audit trail, fed by events in the worker and read on A-08. Other
 * modules reach it only through {@link AUDIT_SERVICE}.
 */
@Global()
@Module({
  controllers: [AuditController],
  providers: [
    AuditLog,
    AuditSubscribers,
    { provide: ENTRY_REPOSITORY, useClass: PostgresEntryRepository },
    { provide: AUDIT_SERVICE, useClass: InProcessAuditService },
  ],
  exports: [AUDIT_SERVICE],
})
export class AuditModule {}
