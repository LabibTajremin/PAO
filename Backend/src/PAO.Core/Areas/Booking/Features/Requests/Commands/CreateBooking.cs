using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Requests.Commands;

/// <summary>
/// A customer's booking request (C-06) with every snapshot copied in (PRD §5, §9.3 rule 4).
/// It writes in its own transaction: a repeated idempotency key is read back after the
/// failed insert rolls back, and returns the stored booking (PRD §9.6).
/// </summary>
public sealed record CreateBooking(Guid CustomerId, string IdempotencyKey, BookingCreateInput Input) : IRequest<BookingView>;

/// <summary>Checks <see cref="CreateBooking"/> with the reasons the error map knows.</summary>
public sealed class CreateBookingValidator : AbstractValidator<CreateBooking>
{
    /// <summary>A key, one to ten items, a note of at most 500 characters and a time for a scheduled job.</summary>
    public CreateBookingValidator() => RuleFor(r => r).Custom((r, _) =>
    {
        var note = r.Input.Note ?? string.Empty;
        var invalid = string.IsNullOrWhiteSpace(r.IdempotencyKey) || r.Input.Items.Count is 0 or > 10
            || note.EnumerateRunes().Count() > 500 || (r.Input.Timing == "scheduled" && r.Input.ScheduledAt is null);
        if (invalid)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
    });
}

/// <summary>Answers <see cref="CreateBooking"/>.</summary>
public sealed class CreateBookingHandler(BookingAccess access, BookingPricing pricing, BookingPeers peers, IMapper mapper) : IRequestHandler<CreateBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(CreateBooking request, CancellationToken cancellationToken)
    {
        var now = access.Now;
        var input = request.Input;
        var at = input.Timing == "scheduled" ? input.ScheduledAt?.ToUniversalTime() : null;
        if (at <= now)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        var booking = await Draft(request, now, at, cancellationToken);
        var (stored, _) = await access.Repository.Create(booking, b => access.Event(
            new BookingRequested { AcceptDeadline = IsoTime.Format(b.AcceptDeadline), Scheduled = b.Scheduled, TotalPaisa = b.TotalPaisa }, b), cancellationToken);
        return mapper.Customer(stored);
    }

    private async Task<StoredBooking> Draft(CreateBooking request, DateTimeOffset now, DateTimeOffset? at, CancellationToken cancellationToken)
    {
        var input = request.Input;
        var service = await pricing.Service(input.ServiceId, cancellationToken);
        var lines = await pricing.Lines(service.Id, input.Items, 0, cancellationToken);
        var (customer, address, provider) = await pricing.Sides(request.CustomerId, input.AddressId, input.ProviderId, service.Id, cancellationToken);
        var rules = await peers.Rules(cancellationToken);
        var wait = TimeSpan.FromMilliseconds(at is null ? rules.AcceptTimeoutAsapMs : rules.AcceptTimeoutScheduledMs);
        var entry = new TimelineEntry(access.NewId(), BookingStatus.Requested, BookingActor.Customer, string.Empty, now);
        return new StoredBooking
        {
            Id = access.NewId(),
            Customer = customer,
            Provider = new BookingParty(input.ProviderId, provider.FullName, provider.Phone),
            ServiceId = service.Id,
            ServiceName = service.Name,
            ServiceModel = service.Model,
            Address = address,
            Note = (input.Note ?? string.Empty).Trim(),
            Status = BookingStatus.Requested,
            Scheduled = at is not null,
            ScheduledAt = at,
            EndsAt = EndsAt(service, at ?? now, lines),
            AcceptDeadline = now + wait,
            TotalPaisa = BookingStates.Total(lines),
            IdempotencyKey = request.IdempotencyKey,
            CreatedAt = now,
            Lines = lines,
            Timeline = { entry },
            NewEvents = { entry },
        };
    }

    /// <summary>The end of a duration hire: the start plus the booked days or hours of its first line.</summary>
    public static DateTimeOffset? EndsAt(CatalogService service, DateTimeOffset start, IReadOnlyList<BookingLine> lines) =>
        service.Model != "duration_hire" || lines.Count == 0 ? null
        : lines[0].Unit == "day" ? start.AddDays(lines[0].Quantity) : start.AddHours(lines[0].Quantity);
}
