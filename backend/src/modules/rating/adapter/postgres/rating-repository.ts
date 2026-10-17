import { Inject, Injectable } from '@nestjs/common';
import { NIL as NIL_UUID } from 'uuid';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database, isUniqueViolation } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';
import { type Aggregate } from '../../domain/aggregate';
import {
  RatingReasons,
  type Review,
  type Reviewable,
  type ReviewRole,
  subjectRole,
} from '../../domain/review';
import { type Page, type RatingRepository } from '../../port/repository';
import {
  addReviewable,
  addToAggregate,
  aggregates,
  type AggregatesRow,
  hasReviewed,
  insertReview,
  reviewableByID,
  reviews,
} from './sqlc/queries_sql';

type AggregateRow = Omit<AggregatesRow, 'subjectId'>;

function aggregate(r: AggregateRow): Aggregate {
  return {
    count: r.reviewCount,
    sum: Number(r.starSum),
    distribution: [r.stars_1, r.stars_2, r.stars_3, r.stars_4, r.stars_5],
  };
}

/** The rating schema. */
@Injectable()
export class PostgresRatingRepository implements RatingRepository {
  private readonly outbox: OutboxWriter;

  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(ID_GENERATOR) ids: IdGenerator,
    @Inject(CLOCK) clock: Clock,
  ) {
    this.outbox = new OutboxWriter('rating', ids, clock);
  }

  addReviewable(b: Reviewable): Promise<void> {
    return addReviewable(this.db.pool, {
      ...b,
      serviceNameEn: b.serviceName.en,
      serviceNameBn: b.serviceName.bn,
    });
  }

  async reviewable(bookingId: string): Promise<Reviewable> {
    const row = await reviewableByID(this.db.pool, { bookingId });
    if (row === null) {
      throw new DomainError(RatingReasons.NotAllowed);
    }
    const { serviceNameEn: en, serviceNameBn: bn, ...rest } = row;
    return { ...rest, serviceName: { en, bn } };
  }

  async submit(r: Review, event: (a: Aggregate) => DomainEvent): Promise<Aggregate> {
    try {
      return await this.db.transaction(async (tx) => {
        await insertReview(tx, {
          ...r,
          tags: [...r.tags],
          serviceNameEn: r.serviceName.en,
          serviceNameBn: r.serviceName.bn,
        });
        const row = await addToAggregate(tx, {
          subjectId: r.subjectId,
          subjectRole: subjectRole(r.authorRole),
          stars: r.stars,
        });
        // The upsert always returns its row.
        const a = aggregate(row as AggregateRow);
        await this.outbox.write(tx, r.subjectId, event(a));
        return a;
      });
    } catch (err) {
      if (isUniqueViolation(err)) {
        throw new DomainError(RatingReasons.AlreadyReviewed, { cause: err });
      }
      throw err;
    }
  }

  async aggregates(role: ReviewRole, ids: readonly string[]): Promise<Map<string, Aggregate>> {
    const rows = await aggregates(this.db.pool, { subjectRole: role, ids: [...ids] });
    return new Map(rows.map((r) => [r.subjectId, aggregate(r)]));
  }

  async reviews(subjectId: string, authorRole: ReviewRole, page: Page): Promise<Review[]> {
    const rows = await reviews(this.db.pool, {
      subjectId,
      authorRole,
      beforeAt: page.before?.createdAt ?? null,
      beforeId: page.before?.id ?? NIL_UUID,
      maxRows: String(page.limit),
    });
    return rows.map(({ serviceNameEn: en, serviceNameBn: bn, authorRole: role, ...r }) => ({
      ...r,
      authorRole: role as ReviewRole,
      serviceName: { en, bn },
    }));
  }

  async hasReviewed(bookingId: string, authorId: string): Promise<boolean> {
    return (await hasReviewed(this.db.pool, { bookingId, authorId }))?.exists === true;
  }
}
