using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Subscriptions.Commands;

/// <summary>The customer pauses, resumes or cancels the dates not yet made into bookings (ADR-0041 §5).</summary>
public sealed record SetSubscriptionStatus(Guid CustomerId, Guid SubscriptionId, string Status) : ICommand<SubscriptionView>;

/// <summary>The customer skips, brings back or changes one date before its cutoff.</summary>
public sealed record ChangeDelivery(Guid CustomerId, Guid SubscriptionId, DateOnly Date, DeliveryChangeInput Input) : ICommand<DeliveryDateView>;

/// <summary>Answers <see cref="SetSubscriptionStatus"/>.</summary>
public sealed class SetSubscriptionStatusHandler(SubscriptionAccess access, IMapper mapper) : IRequestHandler<SetSubscriptionStatus, SubscriptionView>
{
    /// <summary>The statuses each move may start from.</summary>
    private static readonly Dictionary<string, string[]> From = new()
    {
        [SubscriptionStatus.Paused] = [SubscriptionStatus.Active],
        [SubscriptionStatus.Active] = [SubscriptionStatus.Paused],
        [SubscriptionStatus.Cancelled] = [SubscriptionStatus.Requested, SubscriptionStatus.Active, SubscriptionStatus.Paused],
    };

    /// <inheritdoc />
    public async Task<SubscriptionView> Handle(SetSubscriptionStatus request, CancellationToken cancellationToken)
    {
        var s = await access.Change(request.SubscriptionId, request.CustomerId, Side.Customer, s =>
        {
            if (!From[request.Status].Contains(s.Status))
            {
                throw new DomainException(BookingReasons.InvalidTransition);
            }
            s.Status = request.Status;
            return access.Event(new SubscriptionChanged { Status = request.Status }, s);
        }, cancellationToken);
        return mapper.Customer(s, await access.Upcoming(s, cancellationToken));
    }
}

/// <summary>Answers <see cref="ChangeDelivery"/>.</summary>
public sealed class ChangeDeliveryHandler(SubscriptionAccess access) : IRequestHandler<ChangeDelivery, DeliveryDateView>
{
    /// <inheritdoc />
    public async Task<DeliveryDateView> Handle(ChangeDelivery request, CancellationToken cancellationToken)
    {
        var holidays = await access.Holidays(cancellationToken);
        var s = await access.Change(request.SubscriptionId, request.CustomerId, Side.Customer, s =>
        {
            DeliveryDates.EnsureChangeable(s, request.Date, access.Now, holidays);
            var input = request.Input;
            if (input.Items is { } items)
            {
                s.Dates[request.Date] = new SubscriptionDate(request.Date, DateState.Changed, Reprice(s, items), null, null);
            }
            else if (input.Skip is true)
            {
                s.Dates[request.Date] = new SubscriptionDate(request.Date, DateState.Skipped, null, null, null);
            }
            else if (input.Skip is false)
            {
                s.Dates.Remove(request.Date);
            }
            else
            {
                throw new DomainException(BookingReasons.Invalid);
            }
            var skipped = s.Dates.TryGetValue(request.Date, out var row) && row.State == DateState.Skipped;
            return access.Event(new DeliveryDateChanged { Date = EarningsCalendar.Iso(request.Date), Skipped = skipped }, s);
        }, cancellationToken);
        return SubscriptionSides.Date(SubscriptionDays.Day(s, request.Date, access.Now));
    }

    /// <summary>The date's lines at the prices of the order; only the ordered sub-services, 1 to 50 each.</summary>
    private static IReadOnlyList<BookingLine> Reprice(StoredSubscription s, IReadOnlyList<BookingItemInput> items)
    {
        if (items.Count is 0 or > 10 || items.Select(i => i.SubServiceId).Distinct().Count() != items.Count)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        return [.. items.Select((item, position) =>
        {
            var line = s.Lines.FirstOrDefault(l => l.SubServiceId == item.SubServiceId);
            return line is null || item.Quantity is < 1 or > 50
                ? throw new DomainException(BookingReasons.Invalid)
                : line with { Quantity = item.Quantity, TotalPaisa = line.UnitPaisa * item.Quantity, Position = position };
        })];
    }
}

/// <summary>The checks before one date changes.</summary>
public static class DeliveryDates
{
    /// <summary>
    /// The subscription is open, the date is one of its dates, not yet a booking or declined,
    /// and its cutoff has not passed.
    /// </summary>
    public static void EnsureChangeable(StoredSubscription s, DateOnly date, DateTimeOffset now, IReadOnlySet<DateOnly> holidays)
    {
        var planned = DeliveryCalendar.Dates(s.Plan, date, holidays).Contains(date) || s.Dates.ContainsKey(date);
        if (!planned)
        {
            throw new DomainException(BookingReasons.NotFound);
        }
        var row = s.Dates.GetValueOrDefault(date);
        if (s.Status is not (SubscriptionStatus.Requested or SubscriptionStatus.Active) || row?.State is DateState.Booked or DateState.Declined or DateState.Cancelled)
        {
            throw new DomainException(BookingReasons.InvalidTransition);
        }
        if (now >= DeliveryCalendar.Cutoff(date, s.Cutoff))
        {
            throw new DomainException(BookingReasons.CutoffPassed);
        }
    }
}
