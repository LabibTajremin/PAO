import { type DomainEvent } from './domain-event';

/** A stored event as subscribers receive it. */
export interface Envelope<E extends DomainEvent = DomainEvent> {
  readonly id: string;
  /** The module whose outbox held the event. */
  readonly module: string;
  readonly name: E['name'];
  readonly aggregateId: string;
  readonly payload: E;
  readonly occurredAt: Date;
}

/** Processes one event. Delivery is at least once, so handlers must be idempotent. */
export type EventHandler<E extends DomainEvent = DomainEvent> = (env: Envelope<E>) => Promise<void>;

/** Delivers an event to its subscribers. */
export interface Dispatcher {
  dispatch(env: Envelope): Promise<void>;
}

interface Subscription {
  readonly name: string;
  readonly handler: EventHandler;
}

/**
 * Routes events to the subscribers modules register at start-up. It is in-process; the
 * interface lets a broker replace it later (PRD §9.3 rule 5).
 */
export class EventBus implements Dispatcher {
  private readonly subscriptions = new Map<string, Subscription[]>();

  /** Registers `handler`, identified by `handlerName`, for events called `eventName`. */
  subscribe<E extends DomainEvent>(
    eventName: E['name'],
    handlerName: string,
    handler: EventHandler<E>,
  ): void {
    const list = this.subscriptions.get(eventName) ?? [];
    list.push({ name: handlerName, handler: handler as EventHandler });
    this.subscriptions.set(eventName, list);
  }

  /**
   * Delivers `env` to every subscriber. When any fails, the relay retries the event for
   * all of them, which idempotent handlers tolerate.
   */
  async dispatch(env: Envelope): Promise<void> {
    const failures: string[] = [];
    for (const s of this.subscriptions.get(env.name) ?? []) {
      try {
        await s.handler(env);
      } catch (err) {
        failures.push(`${s.name}: ${err instanceof Error ? err.message : String(err)}`);
      }
    }
    if (failures.length > 0) {
      throw new Error(failures.join('\n'));
    }
  }
}
