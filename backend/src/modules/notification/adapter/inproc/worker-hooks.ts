import { Injectable } from '@nestjs/common';
import { type EventBus } from '../../../../platform/events/event-bus';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { Payload } from '../../../../platform/events/payload';
import { IdentityEvents } from '../../../identity/contract/events';
import { EventNotes } from '../../app/event-notes';
import { Inbox } from '../../app/inbox';

/**
 * Notifies on every event that concerns someone. Inbox rows are unique per event and
 * recipient, so redelivery neither duplicates nor re-pushes. Deleted accounts lose their
 * inbox and devices (PRD §11).
 */
@Injectable()
@WorkerHooksProvider()
export class NotificationWorker implements WorkerHooks {
  constructor(
    private readonly notes: EventNotes,
    private readonly inbox: Inbox,
  ) {}

  subscribe(bus: EventBus): void {
    for (const [name, handler] of Object.entries(this.notes.handlers())) {
      bus.subscribe(name, 'notification', handler);
    }
    bus.subscribe(IdentityEvents.AccountDeleted, 'notification', (env) =>
      this.inbox.forget(new Payload(env).id('accountId')),
    );
  }
}
