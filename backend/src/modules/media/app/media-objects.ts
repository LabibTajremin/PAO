import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { type MediaObject } from '../domain/media';
import {
  FILE_STORE,
  type FileStore,
  MEDIA_REPOSITORY,
  type MediaRepository,
} from '../port/media-ports';

/** Uploads never attached to a record within a day are purged. */
export const ORPHAN_AFTER_MS = 24 * 60 * 60_000;

/** Looks up, attaches and removes stored files. */
@Injectable()
export class MediaObjects {
  constructor(
    @Inject(MEDIA_REPOSITORY) private readonly repo: MediaRepository,
    @Inject(FILE_STORE) private readonly files: FileStore,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** An object's record. */
  get(id: string): Promise<MediaObject> {
    return this.repo.get(id);
  }

  /** Spares an object from the orphan purge. */
  markAttached(id: string): Promise<void> {
    return this.repo.markAttached(id);
  }

  /** Removes the file, then its record. */
  async delete(id: string): Promise<void> {
    const object = await this.repo.get(id);
    await this.files.delete(object.bucket, object.key);
    await this.repo.delete(id);
  }

  /** Deletes uploads never attached within a day; returns how many went. */
  async purgeOrphans(): Promise<number> {
    const cutoff = new Date(this.clock.now().getTime() - ORPHAN_AFTER_MS);
    const orphans = await this.repo.orphans(cutoff);
    for (const orphan of orphans) {
      await this.delete(orphan.id);
    }
    return orphans.length;
  }
}
