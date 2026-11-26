using System.Globalization;
using PAO.Core.Areas.Billing.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Areas.Booking;

namespace PAO.Core.Areas.Billing.Services;

/// <summary>
/// Charges the commission when a job completes (handler name `billing`). The ledger holds one
/// commission per booking, so a redelivered event is harmless.
/// </summary>
public sealed class BillingSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus) => bus.Subscribe(BookingEvents.BookingCompleted, "billing", async (envelope, cancellationToken) =>
    {
        var job = Completed(envelope);
        // Without a merchant there is no ledger to debit, and retrying cannot add one, so the
        // event is dropped rather than blocking the outbox.
        if (job.MerchantId == Guid.Empty)
        {
            return;
        }
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IBillingSharedService>().RecordCommission(job, cancellationToken);
    });

    /// <summary>Reads a `booking.BookingCompleted` event; a number that does not parse is left out.</summary>
    public static CommissionRequest Completed(Envelope envelope)
    {
        var p = new EventPayload(envelope);
        var digits = p.Text("number").Split('-')[^1];
        return new CommissionRequest
        {
            BookingId = Guid.Parse(p.Id("bookingId")),
            MerchantId = Guid.Parse(p.Id("providerId")),
            BookingNumber = long.TryParse(digits, NumberStyles.None, CultureInfo.InvariantCulture, out var n) ? n : 0,
            FinalPricePaisa = (long)p.Number("totalPaisa"),
        };
    }
}
