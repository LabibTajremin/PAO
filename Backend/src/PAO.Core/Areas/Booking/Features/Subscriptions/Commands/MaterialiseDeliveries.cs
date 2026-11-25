using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Subscriptions.Commands;

/// <summary>Answers <see cref="MaterialiseDeliveries"/>.</summary>
public sealed class MaterialiseDeliveriesHandler(SubscriptionAccess subscriptions, BookingAccess bookings) : IRequestHandler<MaterialiseDeliveries, int>
{
    /// <summary>The most subscriptions one run reads.</summary>
    public const int Batch = 5000;

    /// <inheritdoc />
    public async Task<int> Handle(MaterialiseDeliveries request, CancellationToken cancellationToken)
    {
        var now = subscriptions.Now;
        var today = DeliveryCalendar.Today(now);
        var holidays = await subscriptions.Holidays(cancellationToken);
        var active = await subscriptions.Repository.WithDates(
            q => q.Where(r => r.Status == SubscriptionStatus.Active && r.StartDate <= today.AddDays(1)), today, today.AddDays(1), Batch, cancellationToken);
        var made = 0;
        foreach (var s in active)
        {
            foreach (var day in SubscriptionDays.Between(s, today, today.AddDays(1), now, holidays).Where(d => Due(s, d, now)))
            {
                await Book(s, day, holidays, cancellationToken);
                made++;
            }
        }
        return made;
    }

    private static bool Due(StoredSubscription s, DayOfSubscription d, DateTimeOffset now) =>
        d.Status == DeliveryStatus.Scheduled && d.BookingId is null
        && now >= DeliveryCalendar.Cutoff(d.Date, s.Cutoff) && now < DeliveryCalendar.At(d.Date, s.Window.To);

    private async Task Book(StoredSubscription s, DayOfSubscription day, IReadOnlySet<DateOnly> holidays, CancellationToken cancellationToken)
    {
        var booking = Draft(s, day);
        var (stored, _) = await bookings.Repository.Create(booking, b => bookings.Event(new DeliveryBooked
        {
            SubscriptionId = s.Id,
            Date = EarningsCalendar.Iso(day.Date),
            Window = DeliveryCalendar.Label(s.Window),
        }, b), cancellationToken);
        await subscriptions.Repository.Change(s.Id, sub =>
        {
            sub.Dates[day.Date] = new SubscriptionDate(day.Date, DateState.Booked, sub.Dates.GetValueOrDefault(day.Date)?.Lines, stored.Id, stored.Status);
            if (SubscriptionDays.Next(sub, day.Date.AddDays(1), holidays) is null)
            {
                sub.Status = SubscriptionStatus.Finished;
            }
            return [];
        }, cancellationToken);
    }

    private StoredBooking Draft(StoredSubscription s, DayOfSubscription day)
    {
        var now = bookings.Now;
        var lines = day.Lines.Select((l, i) => l with { Id = bookings.NewId(), Position = i }).ToList();
        var accepted = new TimelineEntry(bookings.NewId(), BookingStatus.Accepted, BookingActor.System, "scheduled_delivery", now);
        return new StoredBooking
        {
            Id = bookings.NewId(),
            Customer = s.Customer,
            Provider = s.Provider,
            ServiceId = s.ServiceId,
            ServiceName = s.ServiceName,
            ServiceModel = ServiceModel.ScheduledDelivery,
            Address = s.Address,
            Note = s.Note,
            Status = BookingStatus.Accepted,
            Scheduled = true,
            ScheduledAt = DeliveryCalendar.At(day.Date, s.Window.From),
            EndsAt = DeliveryCalendar.At(day.Date, s.Window.To),
            AcceptDeadline = now,
            AcceptedAt = now,
            StartCode = BookingStates.NewStartCode(),
            TotalPaisa = BookingStates.Total(lines),
            IdempotencyKey = $"delivery:{s.Id:N}:{EarningsCalendar.Iso(day.Date)}",
            CreatedAt = now,
            Lines = lines,
            Timeline = { accepted },
            NewEvents = { accepted },
        };
    }
}
