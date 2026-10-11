import { v7 } from 'uuid';

/** Issues identifiers; UUIDv7 in production (04-decisions.md E3), scripted in tests. */
export interface IdGenerator {
  newId(): string;
}

/** Injection token for the {@link IdGenerator}. */
export const ID_GENERATOR = Symbol('IdGenerator');

/** Time-ordered UUIDv7 identifiers. */
export class UuidV7Generator implements IdGenerator {
  newId(): string {
    return v7();
  }
}

/** Returns the given ids in order, then fresh UUIDv7 values; for tests. */
export class SequenceIdGenerator implements IdGenerator {
  private next = 0;

  constructor(private readonly ids: readonly string[]) {}

  newId(): string {
    const id = this.ids[this.next];
    if (id === undefined) {
      return v7();
    }
    this.next += 1;
    return id;
  }
}
