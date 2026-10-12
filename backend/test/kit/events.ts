// Event delivery for specs, as the worker does it: every module's subscribers on one
// bus, fed by the outbox relay or by a hand-made envelope.
import { randomUUID } from 'node:crypto';
import { ModulesContainer } from '@nestjs/core';
import { DATABASE, type Database } from '../../src/platform/db/database';
import { readModuleLists } from '../../src/platform/db/migration-files';
import { type DomainEvent } from '../../src/platform/events/domain-event';
import { type Envelope, EventBus } from '../../src/platform/events/event-bus';
import { discardLogger } from '../../src/platform/logging/logger';
import { OutboxRelay } from '../../src/platform/outbox/outbox-relay';
import { findWorkerHooks } from '../../src/platform/worker/worker-hooks';
import { type TestApi } from './api';

/** A bus with every module's subscribers of the API's app. */
export function subscribedBus(api: TestApi): EventBus {
  const bus = new EventBus();
  for (const hooks of findWorkerHooks(api.app.get(ModulesContainer))) {
    hooks.subscribe?.(bus);
  }
  return bus;
}

/** Delivers every pending outbox event to the subscribers until nothing is left. */
export async function relayEvents(api: TestApi, bus: EventBus = subscribedBus(api)) {
  const relay = new OutboxRelay(
    api.app.get<Database>(DATABASE),
    bus,
    readModuleLists().outboxModules,
    { clock: api.clock, log: discardLogger() },
  );
  for (let pass = 0; pass < 20; pass++) {
    if ((await relay.runOnce()) === 0) {
      return;
    }
  }
  throw new Error('events kept coming after 20 relay passes');
}

/** Wraps `event` as the relay would deliver it. */
export function envelope<E extends DomainEvent>(api: TestApi, event: E): Envelope<E> {
  return {
    id: randomUUID(),
    module: 'test',
    name: event.name,
    aggregateId: '',
    payload: event,
    occurredAt: api.clock.now(),
  };
}

/** Dispatches `event` to every subscriber, failing the spec on error. */
export function deliver(api: TestApi, event: DomainEvent, bus: EventBus = subscribedBus(api)) {
  return bus.dispatch(envelope(api, event));
}
