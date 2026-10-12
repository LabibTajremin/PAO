import { Inject, Injectable } from '@nestjs/common';
import { type EventBus } from '../../../../platform/events/event-bus';
import { type WorkerHooks, WorkerHooksProvider } from '../../../../platform/worker/worker-hooks';
import { AuditLog } from '../../app/audit-log';
import { EVENT_ENTRIES } from '../../app/event-entries';

/**
 * Writes an entry for every audited event in the worker. Entries carry the event id,
 * so a redelivered event cannot add a second one.
 */
@Injectable()
@WorkerHooksProvider()
export class AuditSubscribers implements WorkerHooks {
  constructor(@Inject(AuditLog) private readonly log: AuditLog) {}

  subscribe(bus: EventBus): void {
    for (const [name, toEntry] of Object.entries(EVENT_ENTRIES)) {
      bus.subscribe(name, 'audit', (env) =>
        this.log.record({
          ...toEntry(env.payload as never),
          at: env.occurredAt,
          eventId: env.id,
        }),
      );
    }
  }
}
