using PAO.EF.Booking;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Booking;

/// <summary>A booking row with its items, proposals and timeline, as the repository loads them.</summary>
public sealed record BookingRows(
    BookingRecord Booking, IReadOnlyList<BookingItemRecord> Items, IReadOnlyList<ExtrasProposalRecord> Proposals, IReadOnlyList<TimelineRecord> Timeline);

/// <summary>Maps the `booking` schema rows to the aggregate and list rows.</summary>
public sealed class BookingRecordProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<BookingRows, StoredBooking>((rows, _) => ToStored(rows))
        .Add<BookingRecord, BookingRow>((r, _) => new BookingRow
        {
            Id = r.Id,
            Number = r.Number,
            Status = r.Status,
            ServiceName = new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn },
            CustomerName = r.CustomerName,
            ProviderName = r.ProviderName,
            Scheduled = r.Timing == "scheduled",
            ScheduledAt = r.ScheduledAt,
            TotalPaisa = r.TotalPaisa,
            CreatedAt = r.CreatedAt,
        });

    /// <summary>
    /// Lines of an approved proposal are part of the bill; lines of other proposals stay with
    /// their proposal only.
    /// </summary>
    private static StoredBooking ToStored(BookingRows rows)
    {
        var b = Header(rows.Booking);
        b.Proposals.AddRange(rows.Proposals.Select(p => new ExtrasProposal
        {
            Id = p.Id, Status = p.Status, AddedPaisa = p.AddedPaisa, ProposedAt = p.ProposedAt, DecidedAt = p.DecidedAt, Lines = [],
        }));
        foreach (var item in rows.Items)
        {
            var line = ToLine(item);
            var proposal = b.Proposals.Find(p => p.Id == line.ProposalId);
            proposal?.Lines.Add(line);
            if (proposal is null || proposal.Status == "approved")
            {
                b.Lines.Add(line);
            }
        }
        b.Timeline.AddRange(rows.Timeline.Select(t => new TimelineEntry(t.Id, t.Status, t.Actor, t.Reason, t.At)));
        return b;
    }

    private static StoredBooking Header(BookingRecord r) => new()
    {
            Id = r.Id,
            Number = r.Number,
            Customer = new BookingParty(r.CustomerId, r.CustomerName, r.CustomerPhone),
            Provider = new BookingParty(r.ProviderId, r.ProviderName, r.ProviderPhone),
            ServiceId = r.ServiceId,
            ServiceName = new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn },
            ServiceModel = r.ServiceModel,
            Address = new AddressSnapshot(r.AddressId, r.AddressArea, r.AddressLine1, r.AddressLine2,
                new GeoPoint { Lat = r.AddressLocation.Y, Lng = r.AddressLocation.X }),
            Note = r.Note,
            Status = r.Status,
            Scheduled = r.Timing == "scheduled",
            ScheduledAt = r.ScheduledAt,
            EndsAt = r.EndsAt,
            AcceptDeadline = r.AcceptDeadline,
            TotalPaisa = r.TotalPaisa,
            StartCode = r.StartCode,
            CodeAttempts = r.StartCodeAttempts,
            CodeLockedUntil = r.StartCodeLockedUntil,
            CashReceived = r.CashReceived,
            IdempotencyKey = r.IdempotencyKey,
            CancelReason = r.CancelReason,
            CancelledBy = r.CancelledBy ?? string.Empty,
            RejectReason = r.RejectReason,
            CreatedAt = r.CreatedAt,
            AcceptedAt = r.AcceptedAt,
            StartedAt = r.StartedAt,
            CompletedAt = r.CompletedAt,
            CancelledAt = r.CancelledAt,
    };

    private static BookingLine ToLine(BookingItemRecord i) => new()
    {
        Id = i.Id,
        SubServiceId = i.SubServiceId,
        PriceVersionId = i.PriceVersionId,
        Name = new Text { En = i.NameEn, Bn = i.NameBn },
        Unit = i.Unit,
        Quantity = i.Quantity,
        UnitPaisa = i.UnitPricePaisa,
        TotalPaisa = i.TotalPaisa,
        Extra = i.Extra,
        ProposalId = i.ProposalId,
        Position = i.Position,
    };
}
