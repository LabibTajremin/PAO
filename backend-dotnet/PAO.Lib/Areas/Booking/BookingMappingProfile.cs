using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Booking;

/// <summary>
/// A booking as one side sees it. The rules decide what is shared; the map only shows it:
/// `ShowContacts` reveals both phones, `ExactAddress` the address lines and point.
/// </summary>
public sealed record BookingForSide(StoredBooking Booking, bool ShowContacts, bool ExactAddress, bool Cancellable, bool? Reviewed = null);

/// <summary>A list row with the name of the other side.</summary>
public sealed record BookingRowForSide(BookingRow Row, string Counterpart);

/// <summary>The Booking area's maps.</summary>
public sealed class BookingMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => Rows(Details(registry
        .Add<BookingLine, BookingItemView>((l, _) => new BookingItemView
        {
            SubServiceId = l.SubServiceId,
            PriceVersionId = l.PriceVersionId,
            Name = l.Name,
            Unit = l.Unit,
            Quantity = l.Quantity,
            UnitPrice = l.UnitPaisa,
            Total = l.TotalPaisa,
            Extra = l.Extra,
        })
        .Add<BookingForSide, BookingView>(View)));

    private static MappingRegistry Details(MappingRegistry registry) => registry
        .Add<StoredBooking, ReceiptView>((b, m) => new ReceiptView
        {
            BookingId = b.Id,
            Number = b.DisplayNumber,
            CompletedAt = IsoTime.Format(b.CompletedAt ?? b.CreatedAt),
            ServiceName = b.ServiceName,
            ProviderName = b.Provider.Name,
            CustomerName = b.Customer.Name,
            Area = b.Address.Area,
            Items = m.MapAll<BookingLine, BookingItemView>(b.Lines),
            Total = b.TotalPaisa,
        })
        .Add<StoredBooking, BookingDetails>((b, _) => new BookingDetails
        {
            Id = b.Id,
            Number = b.DisplayNumber,
            Status = b.Status,
            CustomerId = b.Customer.Id,
            ProviderId = b.Provider.Id,
            ServiceId = b.ServiceId,
            ServiceName = b.ServiceName,
            CustomerName = b.Customer.Name,
            ProviderName = b.Provider.Name,
            Area = b.Address.Area,
            TotalPaisa = b.TotalPaisa,
            CreatedAt = b.CreatedAt,
            CompletedAt = b.CompletedAt,
        });

    private static MappingRegistry Rows(MappingRegistry registry) => registry
        .Add<BookingRowForSide, BookingListItemView>((r, _) => new BookingListItemView
        {
            Id = r.Row.Id,
            Number = BookingNumbers.Format(r.Row.Number),
            Status = r.Row.Status,
            ServiceName = r.Row.ServiceName,
            CounterpartName = r.Counterpart,
            Timing = r.Row.Scheduled ? "scheduled" : "asap",
            ScheduledAt = Iso(r.Row.ScheduledAt),
            Total = r.Row.TotalPaisa,
            CreatedAt = IsoTime.Format(r.Row.CreatedAt),
        })
        .Add<BookingRow, BookingSummary>((r, _) => new BookingSummary
        {
            Id = r.Id,
            Number = BookingNumbers.Format(r.Number),
            Status = r.Status,
            ServiceName = r.ServiceName,
            TotalPaisa = r.TotalPaisa,
            CreatedAt = r.CreatedAt,
        })
        .Add<EarningsJob, EarningsJobView>((j, _) => new EarningsJobView
        {
            BookingId = j.Id,
            Number = BookingNumbers.Format(j.Number),
            CompletedAt = IsoTime.Format(j.CompletedAt),
            ServiceName = j.ServiceName,
            Total = j.TotalPaisa,
        });

    /// <summary>An optional time as the API writes it.</summary>
    public static string? Iso(DateTimeOffset? at) => at is { } t ? IsoTime.Format(t) : null;

    private static BookingView View(BookingForSide s, IMapper m)
    {
        var b = s.Booking;
        return new BookingView
        {
            Id = b.Id,
            Number = b.DisplayNumber,
            Status = b.Status,
            ServiceId = b.ServiceId,
            ServiceName = b.ServiceName,
            ServiceModel = b.ServiceModel,
            Provider = Party(b.Provider, s.ShowContacts),
            Customer = Party(b.Customer, s.ShowContacts),
            Items = m.MapAll<BookingLine, BookingItemView>(b.Lines),
            Total = b.TotalPaisa,
            Timing = b.Scheduled ? "scheduled" : "asap",
            ScheduledAt = Iso(b.ScheduledAt),
            EndsAt = Iso(b.EndsAt),
            Address = s.ExactAddress
                ? new BookingAddressView { Area = b.Address.Area, Line1 = b.Address.Line1, Line2 = b.Address.Line2, Location = b.Address.Location }
                : new BookingAddressView { Area = b.Address.Area },
            Note = b.Note,
            AcceptDeadline = IsoTime.Format(b.AcceptDeadline),
            PendingExtras = b.Pending is { } p ? Proposal(b, p, m) : null,
            Cancellable = s.Cancellable,
            CashReceived = b.CashReceived,
            CreatedAt = IsoTime.Format(b.CreatedAt),
            Timeline = [.. b.Timeline.Select(e => new TimelineEntryView
            {
                Status = e.Status,
                At = IsoTime.Format(e.At),
                Actor = e.Actor,
                Reason = e.Reason.Length == 0 ? null : e.Reason,
            })],
            ReviewedByMe = s.Reviewed,
        };
    }

    private static BookingPartyView Party(BookingParty p, bool phone) =>
        new() { Id = p.Id, Name = p.Name, Phone = phone ? p.Phone : null };

    private static ExtrasProposalView Proposal(StoredBooking b, ExtrasProposal p, IMapper m) => new()
    {
        Id = p.Id,
        Items = m.MapAll<BookingLine, BookingItemView>(p.Lines),
        AddedTotal = p.AddedPaisa,
        NewTotal = b.TotalPaisa + p.AddedPaisa,
        Status = p.Status,
        ProposedAt = IsoTime.Format(p.ProposedAt),
    };
}
