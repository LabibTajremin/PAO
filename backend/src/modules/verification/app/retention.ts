import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { CLOSURES, type Closures, FILES, type Files } from '../port/closures';
import { SETTINGS, type Settings } from '../port/peers';

/**
 * Keeps a closed account's verification documents for the retention period, then
 * deletes them with every verification record (PRD §6.6, ADR-0023).
 */
@Injectable()
export class DocumentRetention {
  constructor(
    @Inject(CLOSURES) private readonly closures: Closures,
    @Inject(FILES) private readonly files: Files,
    @Inject(SETTINGS) private readonly settings: Settings,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Starts the retention clock of a deleted account. */
  closed(accountId: string): Promise<void> {
    return this.closures.record(accountId, this.clock.now());
  }

  /** Purges accounts closed longer than the retention setting; returns how many. */
  async purgeExpired(): Promise<number> {
    const { documentRetentionMs } = await this.settings.rules();
    const cutoff = new Date(this.clock.now().getTime() - documentRetentionMs);
    const due = await this.closures.closedBefore(cutoff);
    for (const id of due) {
      // Files first: if a delete fails, the records still point at what is left.
      for (const photo of await this.closures.level2Photos(id)) {
        await this.files.delete(photo);
      }
      await this.files.deleteOwned(id);
      await this.closures.purge(id);
    }
    return due.length;
  }
}
