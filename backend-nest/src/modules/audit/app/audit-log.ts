import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { AuditReasons, type Entry, type Filter, isComplete } from '../domain/entry';
import { ENTRY_REPOSITORY, type EntryRepository, type Page } from '../port/entry-repository';

/** What a caller records; the log fills in the id, and the time unless given. */
export type NewEntry = Omit<Entry, 'id' | 'at' | 'eventId'> & {
  readonly at?: Date;
  readonly eventId?: string | null;
};

/** The append-only audit log (PRD §6.4, A-08). */
@Injectable()
export class AuditLog {
  constructor(
    @Inject(ENTRY_REPOSITORY) private readonly repo: EntryRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Appends an entry. */
  async record(e: NewEntry): Promise<void> {
    if (!isComplete(e)) {
      throw new DomainError(AuditReasons.Invalid);
    }
    await this.repo.append({
      ...e,
      id: this.ids.newId(),
      at: e.at ?? this.clock.now(),
      eventId: e.eventId ?? null,
    });
  }

  /** A page of entries, newest first. */
  list(f: Filter, page: Page): Promise<Entry[]> {
    return this.repo.list(f, page);
  }
}
