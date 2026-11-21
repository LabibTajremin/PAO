using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Rating;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Rating.Repositories;

/// <summary>Stores reviewable bookings, reviews and the running aggregates (`rating` schema).</summary>
public sealed class RatingRepository(PaoDbContext db, OutboxWriter outbox, IMapper mapper)
{
    /// <summary>Opens a booking for review; adding it twice is a no-op, so a redelivered event is harmless.</summary>
    public Task AddReviewable(Reviewable b, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO rating.reviewable_bookings (booking_id, customer_id, provider_id, customer_name, provider_name, service_name_en, service_name_bn, completed_at)
        VALUES ({b.BookingId}, {b.CustomerId}, {b.ProviderId}, {b.CustomerName}, {b.ProviderName}, {b.ServiceName.En}, {b.ServiceName.Bn}, {b.CompletedAt.ToUniversalTime()})
        ON CONFLICT DO NOTHING
        """, cancellationToken);

    /// <summary>The completed booking; `rating.not_allowed` when there is none.</summary>
    public async Task<Reviewable> Reviewable(Guid bookingId, CancellationToken cancellationToken)
    {
        var r = await db.Set<ReviewableBookingRecord>().AsNoTracking().FirstOrDefaultAsync(x => x.BookingId == bookingId, cancellationToken)
            ?? throw new DomainException(RatingReasons.NotAllowed);
        return new Reviewable(r.BookingId, r.CustomerId, r.ProviderId, r.CustomerName, r.ProviderName, new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn }, r.CompletedAt);
    }

    /// <summary>
    /// Stores the review, adds it to the subject's aggregate and writes the event built from
    /// the new aggregate, in the command's transaction. A second review of a booking by the
    /// same side is `rating.already_reviewed`.
    /// </summary>
    public async Task<Aggregate> Submit(Review r, Func<Aggregate, IDomainEvent> domainEvent, CancellationToken cancellationToken)
    {
        db.Add(new ReviewRecord
        {
            Id = r.Id,
            BookingId = r.BookingId,
            AuthorId = r.AuthorId,
            AuthorRole = r.AuthorRole,
            AuthorName = r.AuthorName,
            SubjectId = r.SubjectId,
            Stars = r.Stars,
            Tags = [.. r.Tags],
            Comment = r.Comment,
            ServiceNameEn = r.ServiceName.En,
            ServiceNameBn = r.ServiceName.Bn,
            CreatedAt = r.CreatedAt,
        });
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException error) when (PostgresErrors.IsUniqueViolation(error))
        {
            throw new DomainException(RatingReasons.AlreadyReviewed, error);
        }
        finally
        {
            db.ChangeTracker.Clear();
        }
        var aggregate = await AddToAggregate(r, cancellationToken);
        await outbox.Write(db, Schemas.Rating, r.SubjectId.ToString(), domainEvent(aggregate), cancellationToken);
        return aggregate;
    }

    private async Task<Aggregate> AddToAggregate(Review r, CancellationToken cancellationToken)
    {
        var role = ReviewRole.SubjectOf(r.AuthorRole);
        var row = (await db.Set<RatingAggregateRecord>().FromSql($"""
            INSERT INTO rating.aggregates (subject_id, subject_role, review_count, star_sum, stars_1, stars_2, stars_3, stars_4, stars_5)
            VALUES ({r.SubjectId}, {role}, 1, {r.Stars}, ({r.Stars} = 1)::int, ({r.Stars} = 2)::int, ({r.Stars} = 3)::int, ({r.Stars} = 4)::int, ({r.Stars} = 5)::int)
            ON CONFLICT (subject_id, subject_role) DO UPDATE SET review_count = rating.aggregates.review_count + 1,
                star_sum = rating.aggregates.star_sum + excluded.star_sum, stars_1 = rating.aggregates.stars_1 + excluded.stars_1,
                stars_2 = rating.aggregates.stars_2 + excluded.stars_2, stars_3 = rating.aggregates.stars_3 + excluded.stars_3,
                stars_4 = rating.aggregates.stars_4 + excluded.stars_4, stars_5 = rating.aggregates.stars_5 + excluded.stars_5
            RETURNING *
            """).AsNoTracking().ToListAsync(cancellationToken))[0];
        return mapper.Map<RatingAggregateRecord, Aggregate>(row);
    }

    /// <summary>Aggregates of the subjects of a role among `ids`; unrated subjects are missing.</summary>
    public async Task<IReadOnlyDictionary<Guid, Aggregate>> Aggregates(string role, IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken)
    {
        var rows = await db.Set<RatingAggregateRecord>().AsNoTracking().Where(a => a.SubjectRole == role && ids.Contains(a.SubjectId)).ToListAsync(cancellationToken);
        return rows.ToDictionary(r => r.SubjectId, mapper.Map<RatingAggregateRecord, Aggregate>);
    }

    /// <summary>Reviews of a subject written by a role, newest first, strictly before (at, id).</summary>
    public async Task<IReadOnlyList<Review>> Reviews(Guid subjectId, string authorRole, DateTimeOffset? beforeAt, Guid? beforeId, int limit, CancellationToken cancellationToken)
    {
        var rows = await db.Set<ReviewRecord>().FromSql($"""
            SELECT * FROM rating.reviews
            WHERE subject_id = {subjectId} AND author_role = {authorRole}
              AND ({beforeAt}::timestamptz IS NULL OR (created_at, id) < ({beforeAt}::timestamptz, {beforeId ?? Guid.Empty}))
            ORDER BY created_at DESC, id DESC LIMIT {limit}
            """).AsNoTracking().ToListAsync(cancellationToken);
        return mapper.MapAll<ReviewRecord, Review>(rows);
    }

    /// <summary>Whether the author already reviewed the booking.</summary>
    public Task<bool> HasReviewed(Guid bookingId, Guid authorId, CancellationToken cancellationToken) =>
        db.Set<ReviewRecord>().AnyAsync(r => r.BookingId == bookingId && r.AuthorId == authorId, cancellationToken);

    /// <summary>Drops a deleted account's name and comments (PRD §11); the stars stay so the other side's average does not change.</summary>
    public async Task Erase(Guid accountId, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlAsync($"UPDATE rating.reviews SET author_name = '', comment = '' WHERE author_id = {accountId}", cancellationToken);
        await db.Database.ExecuteSqlAsync($"""
            UPDATE rating.reviewable_bookings
            SET customer_name = CASE WHEN customer_id = {accountId} THEN '' ELSE customer_name END,
                provider_name = CASE WHEN provider_id = {accountId} THEN '' ELSE provider_name END
            WHERE customer_id = {accountId} OR provider_id = {accountId}
            """, cancellationToken);
    }
}
