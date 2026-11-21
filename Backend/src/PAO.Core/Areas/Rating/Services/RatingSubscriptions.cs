using System.Text.Json;
using PAO.Core.Areas.Rating.Features.Reviews.Commands;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Rating.Services;

/// <summary>
/// Opens completed bookings for review and erases deleted authors. Both are idempotent, so
/// a redelivered event is harmless (handler name `rating`, kept from earlier releases).
/// </summary>
public sealed class RatingSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    // Go decoded a missing time as its zero time; an invalid date would fail forever.
    private static readonly DateTimeOffset GoZeroTime = DateTimeOffset.MinValue;

    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        bus.Subscribe(BookingEvents.BookingCompleted, "rating", (envelope, ct) => Send(new OpenReviewable(Completed(envelope)), ct));
        bus.Subscribe(IdentityEvents.AccountDeleted, "rating", (envelope, ct) =>
            Send(new EraseReviewAuthor(Guid.Parse(new EventPayload(envelope).Id("accountId"))), ct));
    }

    /// <summary>Reads a `booking.BookingCompleted` event; missing fields are empty values.</summary>
    public static Reviewable Completed(Envelope envelope)
    {
        var p = new EventPayload(envelope);
        var name = envelope.Payload.TryGetProperty("serviceName", out var n) && n.ValueKind == JsonValueKind.Object
            ? new EventPayload(envelope with { Payload = n })
            : null;
        var at = p.Text("at");
        return new Reviewable(
            Guid.Parse(p.Id("bookingId")), Guid.Parse(p.Id("customerId")), Guid.Parse(p.Id("providerId")),
            p.Text("customerName"), p.Text("providerName"),
            new Text { En = name?.Text("en") ?? string.Empty, Bn = name?.Text("bn") ?? string.Empty },
            at.Length == 0 ? GoZeroTime : DateTimeOffset.Parse(at, System.Globalization.CultureInfo.InvariantCulture));
    }

    private async Task Send(IRequest<Unit> request, CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(request, cancellationToken);
    }
}
