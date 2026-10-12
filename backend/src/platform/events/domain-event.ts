/**
 * A domain event (PRD §9.3 rule 5). The name is stable across releases because events
 * are stored in the outbox; payloads are JSON-safe (ids and times as strings, money as
 * integer paisa) so a relayed event equals the published one.
 */
export interface DomainEvent<Name extends string = string> {
  readonly name: Name;
}
