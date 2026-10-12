import { type Entry, type Filter } from '../domain/entry';

/** A cursor position: entries strictly older than (at, id), at most `limit` of them. */
export interface Page {
  readonly after?: { readonly at: Date; readonly id: string };
  readonly limit: number;
}

/**
 * Appends and reads entries; there is deliberately no update or delete. An entry for an
 * event that was already audited is skipped.
 */
export interface EntryRepository {
  append(e: Entry): Promise<void>;
  list(f: Filter, page: Page): Promise<Entry[]>;
}

/** Injection token for the {@link EntryRepository}. */
export const ENTRY_REPOSITORY = Symbol('EntryRepository');
