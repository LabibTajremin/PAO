import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type MediaObject, MediaReason } from '../../domain/media';
import { type MediaRepository } from '../../port/media-ports';
import * as sql from './sqlc/queries_sql';

function toObject(row: sql.ObjectByIDRow): MediaObject {
  return {
    id: row.id,
    ownerId: row.ownerId,
    purpose: row.purpose,
    contentType: row.contentType,
    sizeBytes: Number(row.sizeBytes),
    bucket: row.bucket,
    key: row.objectKey,
    confirmed: row.status === 'confirmed',
    attached: row.attached,
    createdAt: row.createdAt,
  };
}

/** Stores `media.objects` rows. */
@Injectable()
export class PostgresMediaRepository implements MediaRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  create(o: MediaObject): Promise<void> {
    return sql.createObject(this.db.pool, {
      id: o.id,
      ownerId: o.ownerId,
      purpose: o.purpose,
      contentType: o.contentType,
      sizeBytes: String(o.sizeBytes),
      bucket: o.bucket,
      objectKey: o.key,
      createdAt: o.createdAt,
    });
  }

  async get(id: string): Promise<MediaObject> {
    const row = await sql.objectByID(this.db.pool, { id });
    if (!row) {
      throw new DomainError(MediaReason.NotFound);
    }
    return toObject(row);
  }

  markConfirmed(id: string): Promise<void> {
    return sql.markConfirmed(this.db.pool, { id, confirmedAt: this.clock.now() });
  }

  async markAttached(id: string): Promise<void> {
    const res = await this.db.query(sql.markAttachedQuery, [id]);
    if (res.rowCount === 0) {
      throw new DomainError(MediaReason.NotFound);
    }
  }

  delete(id: string): Promise<void> {
    return sql.deleteObject(this.db.pool, { id });
  }

  async byOwner(ownerId: string): Promise<MediaObject[]> {
    return (await sql.objectsByOwner(this.db.pool, { ownerId })).map(toObject);
  }

  async orphans(createdBefore: Date): Promise<MediaObject[]> {
    return (await sql.orphans(this.db.pool, { createdAt: createdBefore })).map(toObject);
  }
}
