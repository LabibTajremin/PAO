using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Booking;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Booking.Repositories;

/// <summary>Reads bookings: one booking in four queries, lists, the monitor, earnings and counters.</summary>
public sealed class BookingQueries(PaoDbContext db, IMapper mapper)
{
    // Keyset queries ignore the id without a time; any uuid satisfies the parameter type.
    private static readonly Guid NoId = Guid.Empty;

    /// <summary>The booking with its lines, proposals and timeline; `booking.not_found` without one.</summary>
    public async Task<StoredBooking> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<BookingRecord>().AsNoTracking().FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
            ?? throw new DomainException(BookingReasons.NotFound);
        var proposals = await db.Set<ExtrasProposalRecord>().AsNoTracking().Where(p => p.BookingId == id)
            .OrderBy(p => p.ProposedAt).ThenBy(p => p.Id).ToListAsync(cancellationToken);
        var items = await db.Set<BookingItemRecord>().AsNoTracking().Where(i => i.BookingId == id)
            .OrderBy(i => i.Position).ThenBy(i => i.Id).ToListAsync(cancellationToken);
        var timeline = await db.Set<TimelineRecord>().AsNoTracking().Where(t => t.BookingId == id)
            .OrderBy(t => t.At).ThenBy(t => t.Id).ToListAsync(cancellationToken);
        return mapper.Map<BookingRows, StoredBooking>(new BookingRows(row, items, proposals, timeline));
    }

    /// <summary>The booking a customer created with an idempotency key.</summary>
    public Task<Guid> IdByKey(Guid customerId, string key, CancellationToken cancellationToken) =>
        db.Set<BookingRecord>().Where(b => b.CustomerId == customerId && b.IdempotencyKey == key).Select(b => b.Id).SingleAsync(cancellationToken);

    /// <summary>The provider's active jobs other than `exceptId`.</summary>
    public Task<int> CountActive(Guid providerId, Guid exceptId, CancellationToken cancellationToken) =>
        db.Set<BookingRecord>().CountAsync(
            b => b.ProviderId == providerId && b.Id != exceptId
                && (b.Status == BookingStatus.Accepted || b.Status == BookingStatus.OnTheWay || b.Status == BookingStatus.Arrived || b.Status == BookingStatus.InProgress),
            cancellationToken);

    /// <summary>A party's bookings in `statuses`, newest first.</summary>
    public async Task<IReadOnlyList<BookingRow>> List(Guid partyId, bool asProvider, IReadOnlyList<string> statuses, BookingPage p, CancellationToken cancellationToken)
    {
        var states = statuses.ToArray();
        var rows = await db.Set<BookingRecord>().FromSql($"""
            SELECT * FROM booking.bookings
            WHERE (CASE WHEN {asProvider} THEN provider_id ELSE customer_id END) = {partyId}
              AND status = ANY({states})
              AND ({p.At}::timestamptz IS NULL OR (created_at, id) < ({p.At}::timestamptz, {p.Id ?? NoId}))
            ORDER BY created_at DESC, id DESC LIMIT {p.Limit}
            """).AsNoTracking().ToListAsync(cancellationToken);
        return mapper.MapAll<BookingRecord, BookingRow>(rows);
    }

    /// <summary>Every booking matching the admin filters (A-06), newest first.</summary>
    public async Task<IReadOnlyList<BookingRow>> Monitor(MonitorFilter f, BookingPage p, CancellationToken cancellationToken)
    {
        var rows = await db.Set<BookingRecord>().FromSql($"""
            SELECT * FROM booking.bookings
            WHERE ({f.Status}::text IS NULL OR status = {f.Status}::text)
              AND ({f.ServiceId}::uuid IS NULL OR service_id = {f.ServiceId}::uuid)
              AND ({f.From}::timestamptz IS NULL OR created_at >= {f.From}::timestamptz)
              AND ({f.Until}::timestamptz IS NULL OR created_at < {f.Until}::timestamptz)
              AND ({f.Area} = '' OR lower(address_area) = lower({f.Area}))
              AND ({p.At}::timestamptz IS NULL OR (created_at, id) < ({p.At}::timestamptz, {p.Id ?? NoId}))
            ORDER BY created_at DESC, id DESC LIMIT {p.Limit}
            """).AsNoTracking().ToListAsync(cancellationToken);
        return mapper.MapAll<BookingRecord, BookingRow>(rows);
    }

    /// <summary>Requests whose accept deadline passed, oldest first, at most 500 per sweep.</summary>
    public Task<List<Guid>> Due(DateTimeOffset now, CancellationToken cancellationToken) =>
        db.Set<BookingRecord>().Where(b => b.Status == BookingStatus.Requested && b.AcceptDeadline <= now)
            .OrderBy(b => b.AcceptDeadline).Select(b => b.Id).Take(500).ToListAsync(cancellationToken);

    /// <summary>Completed jobs per Dhaka day in [from, until).</summary>
    public async Task<IReadOnlyList<EarningsDay>> EarningsByDay(Guid providerId, DateTimeOffset from, DateTimeOffset until, CancellationToken cancellationToken)
    {
        var rows = await db.Database.SqlQuery<DayRow>($"""
            SELECT (completed_at AT TIME ZONE 'Asia/Dhaka')::date AS "Day", sum(total_paisa)::bigint AS "Total", count(*)::int AS "Jobs"
            FROM booking.bookings
            WHERE provider_id = {providerId} AND status = 'completed' AND completed_at >= {from} AND completed_at < {until}
            GROUP BY 1 ORDER BY 1
            """).ToListAsync(cancellationToken);
        return [.. rows.Select(r => new EarningsDay(r.Day, r.Total, r.Jobs))];
    }

    /// <summary>Completed jobs in [from, until), newest first.</summary>
    public async Task<IReadOnlyList<EarningsJob>> EarningsJobs(Guid providerId, DateTimeOffset from, DateTimeOffset until, BookingPage p, CancellationToken cancellationToken)
    {
        var rows = await db.Set<BookingRecord>().FromSql($"""
            SELECT * FROM booking.bookings
            WHERE provider_id = {providerId} AND status = 'completed' AND completed_at >= {from} AND completed_at < {until}
              AND ({p.At}::timestamptz IS NULL OR (completed_at, id) < ({p.At}::timestamptz, {p.Id ?? NoId}))
            ORDER BY completed_at DESC, id DESC LIMIT {p.Limit}
            """).AsNoTracking().ToListAsync(cancellationToken);
        return [.. rows.Select(r => new EarningsJob(r.Id, r.Number, r.CompletedAt!.Value, new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn }, r.TotalPaisa))];
    }

    /// <summary>Completed jobs, and provider cancellations after acceptance since `since`, in one query.</summary>
    public async Task<(int Completed, int Cancellations)> Stats(Guid providerId, DateTimeOffset since, CancellationToken cancellationToken)
    {
        var row = await db.Database.SqlQuery<StatsRow>($"""
            SELECT count(*) FILTER (WHERE status = 'completed')::int AS "Completed",
                count(*) FILTER (WHERE status = 'cancelled' AND cancelled_by = 'provider' AND accepted_at IS NOT NULL AND cancelled_at > {since})::int AS "Cancellations"
            FROM booking.bookings WHERE provider_id = {providerId}
            """).SingleAsync(cancellationToken);
        return (row.Completed, row.Cancellations);
    }

    private sealed class DayRow
    {
        public DateOnly Day { get; init; }
        public long Total { get; init; }
        public int Jobs { get; init; }
    }

    private sealed class StatsRow
    {
        public int Completed { get; init; }
        public int Cancellations { get; init; }
    }
}
