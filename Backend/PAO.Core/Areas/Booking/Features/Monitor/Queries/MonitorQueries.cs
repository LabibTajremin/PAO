using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Monitor.Queries;

/// <summary>The admin bookings monitor (A-06; ADR-0026 has Booking serve it); filter dates are Dhaka days, `to` included.</summary>
public sealed record MonitorBookings(MonitorInput Input) : IQuery<BookingListView>;

/// <summary>One booking for support, with both parties' contacts and the full timeline.</summary>
public sealed record GetSupportBooking(Guid BookingId) : IQuery<BookingView>;

/// <summary>Checks <see cref="MonitorBookings"/>.</summary>
public sealed class MonitorBookingsValidator : AbstractValidator<MonitorBookings>
{
    /// <summary>The spec has checked the formats.</summary>
    public MonitorBookingsValidator() => RuleFor(r => r.Input).NotNull();
}

/// <summary>Answers <see cref="MonitorBookings"/>; a row names both sides.</summary>
public sealed class MonitorBookingsHandler(BookingAccess access, IMapper mapper) : IRequestHandler<MonitorBookings, BookingListView>
{
    /// <inheritdoc />
    public async Task<BookingListView> Handle(MonitorBookings request, CancellationToken cancellationToken)
    {
        var q = request.Input;
        var (size, page) = BookingPaging.Page(q.Cursor, q.Limit);
        var from = EarningsCalendar.Parse(q.From);
        var to = EarningsCalendar.Parse(q.To);
        var filter = new MonitorFilter(
            q.Status, q.ServiceId,
            from is { } f ? EarningsCalendar.DayStart(f) : null,
            to is { } t ? EarningsCalendar.DayStart(t.AddDays(1)) : null,
            q.Area ?? string.Empty);
        var rows = await access.Queries.Monitor(filter, page, cancellationToken);
        return BookingPaging.List(mapper, rows, size, r => $"{r.CustomerName} → {r.ProviderName}");
    }
}

/// <summary>Answers <see cref="GetSupportBooking"/>.</summary>
public sealed class GetSupportBookingHandler(BookingAccess access, IMapper mapper) : IRequestHandler<GetSupportBooking, BookingView>
{
    /// <inheritdoc />
    public async Task<BookingView> Handle(GetSupportBooking request, CancellationToken cancellationToken) =>
        mapper.Support(await access.Queries.Get(request.BookingId, cancellationToken));
}
