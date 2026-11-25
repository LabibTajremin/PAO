using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Booking;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Booking.Repositories;

/// <summary>Applies a change to a loaded subscription and returns the events to publish with it.</summary>
public delegate IReadOnlyList<IDomainEvent> SubscriptionChange(StoredSubscription subscription);

/// <summary>
/// Reads and writes subscriptions and their stored dates (ADR-0041). Lists read the rows
/// only; a date range reads every subscription's dates with their bookings in one query.
/// </summary>
public sealed class SubscriptionRepository(PaoDbContext db, OutboxWriter outbox, IClock clock)
{
    private const string KeyConstraint = "subscriptions_customer_id_idempotency_key_key";

    /// <summary>Inserts a subscription; a repeated idempotency key returns the stored one.</summary>
    public async Task<StoredSubscription> Create(StoredSubscription s, Func<StoredSubscription, IDomainEvent> domainEvent, CancellationToken cancellationToken)
    {
        await using (var tx = await db.Database.BeginTransactionAsync(cancellationToken))
        {
            try
            {
                var row = SubscriptionRows.ToRecord(s);
                db.Add(row);
                await db.SaveChangesAsync(cancellationToken);
                s.Number = row.Number;
                await outbox.Write(db, Schemas.Booking, s.Id.ToString(), domainEvent(s), cancellationToken);
                await tx.CommitAsync(cancellationToken);
                return s;
            }
            catch (DbUpdateException error) when (PostgresErrors.IsUniqueViolation(error, KeyConstraint))
            {
                await tx.RollbackAsync(cancellationToken);
            }
            finally
            {
                db.ChangeTracker.Clear();
            }
        }
        var id = await db.Set<SubscriptionRecord>().Where(r => r.CustomerId == s.Customer.Id && r.IdempotencyKey == s.IdempotencyKey)
            .Select(r => r.Id).SingleAsync(cancellationToken);
        return await Get(id, cancellationToken);
    }

    /// <summary>A subscription with its stored dates, or `booking.not_found`.</summary>
    public async Task<StoredSubscription> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<SubscriptionRecord>().SingleOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new DomainException(BookingReasons.NotFound);
        var s = SubscriptionRows.ToModel(row);
        foreach (var d in await Dates([id], DateOnly.MinValue, DateOnly.MaxValue, cancellationToken))
        {
            s.Dates[d.Date] = d.Value;
        }
        return s;
    }

    /// <summary>The subscriptions matching <paramref name="filter"/>, newest first, without their dates.</summary>
    public async Task<IReadOnlyList<StoredSubscription>> List(Func<IQueryable<SubscriptionRecord>, IQueryable<SubscriptionRecord>> filter, int limit, CancellationToken cancellationToken)
    {
        var rows = await filter(db.Set<SubscriptionRecord>()).OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id)
            .Take(limit).ToListAsync(cancellationToken);
        return [.. rows.Select(SubscriptionRows.ToModel)];
    }

    /// <summary>The subscriptions matching <paramref name="filter"/> (at most <paramref name="limit"/>) with their dates between two days.</summary>
    public async Task<IReadOnlyList<StoredSubscription>> WithDates(Func<IQueryable<SubscriptionRecord>, IQueryable<SubscriptionRecord>> filter, DateOnly from, DateOnly to, int limit, CancellationToken cancellationToken)
    {
        var subscriptions = await List(filter, limit, cancellationToken);
        var dates = await Dates([.. subscriptions.Select(s => s.Id)], from, to, cancellationToken);
        var byId = subscriptions.ToDictionary(s => s.Id);
        foreach (var d in dates)
        {
            byId[d.SubscriptionId].Dates[d.Date] = d.Value;
        }
        return subscriptions;
    }

    /// <summary>Applies <paramref name="change"/> under the subscription's row lock and saves it with its events.</summary>
    public async Task<StoredSubscription> Change(Guid id, SubscriptionChange change, CancellationToken cancellationToken)
    {
        await using var own = db.Database.CurrentTransaction is null ? await db.Database.BeginTransactionAsync(cancellationToken) : null;
        var locked = await db.Database.SqlQuery<Guid>($"SELECT id AS \"Value\" FROM booking.subscriptions WHERE id = {id} FOR UPDATE").ToListAsync(cancellationToken);
        if (locked.Count == 0)
        {
            throw new DomainException(BookingReasons.NotFound);
        }
        var s = await Get(id, cancellationToken);
        var before = s.Dates.ToDictionary();
        var events = change(s);
        await Save(s, before, cancellationToken);
        foreach (var e in events)
        {
            await outbox.Write(db, Schemas.Booking, id.ToString(), e, cancellationToken);
        }
        if (own is not null)
        {
            await own.CommitAsync(cancellationToken);
        }
        return s;
    }

    /// <summary>Blanks a deleted account's personal details in the snapshots (PRD §11).</summary>
    public async Task Erase(Guid accountId, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlAsync($"""
            UPDATE booking.subscriptions SET customer_name = '', customer_phone = '', address_line1 = '', address_line2 = '', note = '',
                address_lat = round(address_lat::numeric, 2), address_lng = round(address_lng::numeric, 2)
            WHERE customer_id = {accountId}
            """, cancellationToken);
        await db.Database.ExecuteSqlAsync($"UPDATE booking.subscriptions SET provider_name = '', provider_phone = '' WHERE provider_id = {accountId}", cancellationToken);
    }

    private async Task Save(StoredSubscription s, Dictionary<DateOnly, SubscriptionDate> before, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        await db.Set<SubscriptionRecord>().Where(r => r.Id == s.Id).ExecuteUpdateAsync(u => u
            .SetProperty(r => r.Status, s.Status).SetProperty(r => r.DeclineReason, s.DeclineReason)
            .SetProperty(r => r.AcceptedAt, s.AcceptedAt).SetProperty(r => r.UpdatedAt, now), cancellationToken);
        foreach (var (date, d) in s.Dates.Where(p => !before.TryGetValue(p.Key, out var old) || old != p.Value))
        {
            var items = d.Lines is null ? null : SubscriptionRows.LinesJson(d.Lines);
            await db.Database.ExecuteSqlAsync($"""
                INSERT INTO booking.subscription_dates (subscription_id, date, state, items, booking_id, updated_at)
                VALUES ({s.Id}, {date}, {d.State}, {items}::jsonb, {d.BookingId}, {now})
                ON CONFLICT (subscription_id, date) DO UPDATE SET state = excluded.state, items = excluded.items,
                    booking_id = excluded.booking_id, updated_at = excluded.updated_at
                """, cancellationToken);
        }
        foreach (var date in before.Keys.Where(k => !s.Dates.ContainsKey(k)))
        {
            await db.Database.ExecuteSqlAsync($"DELETE FROM booking.subscription_dates WHERE subscription_id = {s.Id} AND date = {date}", cancellationToken);
        }
    }

    private async Task<IReadOnlyList<(Guid SubscriptionId, DateOnly Date, SubscriptionDate Value)>> Dates(Guid[] ids, DateOnly first, DateOnly last, CancellationToken cancellationToken)
    {
        var rows = await (from d in db.Set<SubscriptionDateRecord>()
                          where ids.Contains(d.SubscriptionId) && d.Date >= first && d.Date <= last
                          join b in db.Set<BookingRecord>() on d.BookingId equals b.Id into booked
                          from b in booked.DefaultIfEmpty()
                          select new { d.SubscriptionId, d.Date, d.State, d.Items, d.BookingId, Status = b == null ? null : b.Status })
            .ToListAsync(cancellationToken);
        return [.. rows.Select(r => (r.SubscriptionId, r.Date,
            new SubscriptionDate(r.Date, r.State, r.Items is null ? null : SubscriptionRows.Lines(r.Items), r.BookingId, r.Status)))];
    }
}
