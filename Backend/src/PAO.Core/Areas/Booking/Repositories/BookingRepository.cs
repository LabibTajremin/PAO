using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using PAO.EF;
using PAO.EF.Booking;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Booking.Repositories;

/// <summary>Applies a change to a loaded booking and returns the events to publish with it.</summary>
public delegate Task<IReadOnlyList<IDomainEvent>> BookingChange(StoredBooking booking);

/// <summary>
/// Writes bookings. A change holds the booking's row lock and the provider's advisory lock,
/// so the one-active-job rule and concurrent accepts are decided one at a time. Each write
/// joins the caller's transaction or opens its own, with its events in the same commit.
/// </summary>
public sealed class BookingRepository(PaoDbContext db, BookingQueries queries, OutboxWriter outbox, IClock clock)
{
    private const string KeyConstraint = "bookings_customer_id_idempotency_key_key";
    private const string PairConstraint = "bookings_one_request_per_pair";

    /// <summary>
    /// Inserts a booking; a repeated idempotency key returns the stored booking with
    /// `Created` false (PRD §9.6). `domainEvent` builds the creation event once the number is known.
    /// </summary>
    public async Task<(StoredBooking Booking, bool Created)> Create(StoredBooking b, Func<StoredBooking, IDomainEvent> domainEvent, CancellationToken cancellationToken)
    {
        // A failed insert ends its transaction, so the stored booking is read after the rollback.
        await using (var tx = await db.Database.BeginTransactionAsync(cancellationToken))
        {
            try
            {
                var row = NewRecord(b);
                db.Add(row);
                AddParts(b, []);
                await db.SaveChangesAsync(cancellationToken);
                b.Number = row.Number;
                await outbox.Write(db, Schemas.Booking, b.Id.ToString(), domainEvent(b), cancellationToken);
                await tx.CommitAsync(cancellationToken);
                return (b, true);
            }
            catch (DbUpdateException error) when (PostgresErrors.IsUniqueViolation(error, PairConstraint))
            {
                throw new DomainException(BookingReasons.DuplicateRequest, error);
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
        var stored = await queries.IdByKey(b.Customer.Id, b.IdempotencyKey, cancellationToken);
        return (await queries.Get(stored, cancellationToken), false);
    }

    /// <summary>Applies `change` under the locks and saves the booking with its events.</summary>
    public async Task<StoredBooking> Change(Guid id, BookingChange change, CancellationToken cancellationToken)
    {
        await using var own = db.Database.CurrentTransaction is null ? await db.Database.BeginTransactionAsync(cancellationToken) : null;
        var provider = await db.Database.SqlQuery<Guid>($"SELECT provider_id AS \"Value\" FROM booking.bookings WHERE id = {id} FOR UPDATE")
            .ToListAsync(cancellationToken);
        if (provider.Count == 0)
        {
            throw new DomainException(BookingReasons.NotFound);
        }
        await db.Database.ExecuteSqlAsync($"SELECT pg_advisory_xact_lock(hashtextextended({provider[0]}::text, 0))", cancellationToken);
        var b = await queries.Get(id, cancellationToken);
        b.ProviderActiveJobs = await queries.CountActive(provider[0], id, cancellationToken);
        var events = await change(b);
        await Save(b, cancellationToken);
        foreach (var e in events)
        {
            await outbox.Write(db, Schemas.Booking, id.ToString(), e, cancellationToken);
        }
        if (own is not null)
        {
            await own.CommitAsync(cancellationToken);
        }
        return b;
    }

    /// <summary>
    /// Blanks a deleted account's personal details in the snapshots (PRD §11). The booking
    /// stays for the other side's history and the money trail; both updates are idempotent.
    /// </summary>
    public async Task Erase(Guid accountId, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlAsync($"""
            UPDATE booking.bookings
            SET customer_name = '', customer_phone = '', address_line1 = '', address_line2 = '', note = '',
                address_location = ST_SnapToGrid(address_location::geometry, 0.01)::geography
            WHERE customer_id = {accountId}
            """, cancellationToken);
        await db.Database.ExecuteSqlAsync($"UPDATE booking.bookings SET provider_name = '', provider_phone = '' WHERE provider_id = {accountId}", cancellationToken);
    }

    /// <summary>Writes the changing columns, then lines, proposals and new timeline entries; lines never change once stored.</summary>
    private async Task Save(StoredBooking b, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        string? cancelledBy = b.CancelledBy.Length == 0 ? null : b.CancelledBy;
        await db.Set<BookingRecord>().Where(r => r.Id == b.Id).ExecuteUpdateAsync(u => u
            .SetProperty(r => r.Status, b.Status).SetProperty(r => r.TotalPaisa, b.TotalPaisa)
            .SetProperty(r => r.StartCodeAttempts, b.CodeAttempts).SetProperty(r => r.StartCodeLockedUntil, b.CodeLockedUntil)
            .SetProperty(r => r.CashReceived, b.CashReceived).SetProperty(r => r.CancelReason, b.CancelReason)
            .SetProperty(r => r.CancelledBy, cancelledBy).SetProperty(r => r.RejectReason, b.RejectReason)
            .SetProperty(r => r.AcceptedAt, b.AcceptedAt).SetProperty(r => r.StartedAt, b.StartedAt)
            .SetProperty(r => r.CompletedAt, b.CompletedAt).SetProperty(r => r.CancelledAt, b.CancelledAt)
            .SetProperty(r => r.UpdatedAt, now).SetProperty(r => r.StartCode, b.StartCode),
            cancellationToken);
        var proposals = await db.Set<ExtrasProposalRecord>().AsTracking().Where(p => p.BookingId == b.Id).ToListAsync(cancellationToken);
        var known = await db.Set<BookingItemRecord>().Where(i => i.BookingId == b.Id).Select(i => i.Id).ToListAsync(cancellationToken);
        foreach (var p in proposals)
        {
            var current = b.Proposals.Single(x => x.Id == p.Id);
            p.Status = current.Status;
            p.DecidedAt = current.DecidedAt;
        }
        AddParts(b, [.. proposals.Select(p => p.Id), .. known]);
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
    }

    /// <summary>Adds the proposals, lines and new timeline entries whose ids are not in `stored`.</summary>
    private void AddParts(StoredBooking b, HashSet<Guid> stored)
    {
        db.AddRange(b.Proposals.Where(p => !stored.Contains(p.Id)).Select(p => new ExtrasProposalRecord
        {
            Id = p.Id,
            BookingId = b.Id,
            Status = p.Status,
            AddedPaisa = p.AddedPaisa,
            ProposedAt = p.ProposedAt,
            DecidedAt = p.DecidedAt,
        }));
        var lines = b.Lines.Concat(b.Proposals.SelectMany(p => p.Lines)).DistinctBy(l => l.Id).Where(l => !stored.Contains(l.Id));
        db.AddRange(lines.Select(l => new BookingItemRecord
        {
            Id = l.Id,
            BookingId = b.Id,
            ProposalId = l.ProposalId,
            SubServiceId = l.SubServiceId,
            PriceVersionId = l.PriceVersionId,
            NameEn = l.Name.En,
            NameBn = l.Name.Bn,
            Unit = l.Unit,
            Quantity = l.Quantity,
            UnitPricePaisa = l.UnitPaisa,
            TotalPaisa = l.TotalPaisa,
            Extra = l.Extra,
            Position = l.Position,
        }));
        db.AddRange(b.NewEvents.Select(e => new TimelineRecord { Id = e.Id, BookingId = b.Id, Status = e.Status, Actor = e.Actor, Reason = e.Reason, At = e.At }));
    }

    private static BookingRecord NewRecord(StoredBooking b) => new()
    {
        Id = b.Id,
        CustomerId = b.Customer.Id,
        ProviderId = b.Provider.Id,
        ServiceId = b.ServiceId,
        ServiceNameEn = b.ServiceName.En,
        ServiceNameBn = b.ServiceName.Bn,
        ServiceModel = b.ServiceModel,
        CustomerName = b.Customer.Name,
        CustomerPhone = b.Customer.Phone,
        ProviderName = b.Provider.Name,
        ProviderPhone = b.Provider.Phone,
        AddressId = b.Address.Id,
        AddressArea = b.Address.Area,
        AddressLine1 = b.Address.Line1,
        AddressLine2 = b.Address.Line2,
        AddressLocation = new Point(b.Address.Location.Lng, b.Address.Location.Lat) { SRID = 4326 },
        Note = b.Note,
        Status = b.Status,
        Timing = b.Scheduled ? "scheduled" : "asap",
        ScheduledAt = b.ScheduledAt,
        EndsAt = b.EndsAt,
        AcceptDeadline = b.AcceptDeadline,
        TotalPaisa = b.TotalPaisa,
        StartCode = b.StartCode,
        IdempotencyKey = b.IdempotencyKey,
        CancelReason = string.Empty,
        RejectReason = string.Empty,
        CreatedAt = b.CreatedAt,
        UpdatedAt = b.CreatedAt,
    };
}
