using System.Text.Json;
using PAO.Core.Areas.Billing.Services;
using PAO.Core.Areas.Notification.Services;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Billing;

namespace PAO.UnitTests.Areas;

public sealed class BillingRuleTests
{
    [Theory]
    [InlineData(100_000L, 1000, 10_000L)]
    [InlineData(105L, 1000, 11L)]
    [InlineData(104L, 1000, 10L)]
    [InlineData(115L, 1000, 12L)]
    [InlineData(0L, 1000, 0L)]
    [InlineData(-5L, 1000, 0L)]
    [InlineData(100_000L, 0, 0L)]
    [InlineData(99_999L, 10_000, 99_999L)]
    public void Charges_the_rate_rounded_half_up(long total, int rateBp, long expected)
    {
        Assert.Equal(expected, BillingRules.Commission(total, rateBp));
    }

    [Fact]
    public void The_due_is_debits_minus_confirmed_credits_never_negative_and_blocks_only_above_the_limit()
    {
        Assert.Equal(4000, new DueTotals(10_000, 6000, 999).DuePaisa);
        Assert.Equal(0, new DueTotals(1000, 6000, 0).DuePaisa);
        Assert.False(new DueWithLimits(new DueTotals(5000, 0, 0), 1000, 5000).Blocked);
        Assert.True(new DueWithLimits(new DueTotals(5001, 0, 0), 1000, 5000).Blocked);
    }

    private static Envelope Completed(object payload) => new()
    {
        Id = Guid.NewGuid(),
        Module = "booking",
        Name = "booking.BookingCompleted",
        AggregateId = string.Empty,
        OccurredAt = DateTimeOffset.UnixEpoch,
        Payload = JsonSerializer.SerializeToElement(payload, JsonSerializerOptions.Web),
    };

    [Fact]
    public void Reads_the_completed_job_and_leaves_out_a_number_that_does_not_parse()
    {
        var booking = Guid.NewGuid();
        var provider = Guid.NewGuid();
        var job = BillingSubscriptions.Completed(Completed(new { bookingId = booking, providerId = provider, number = "PAO-104233", totalPaisa = 113_000 }));
        Assert.Equal((booking, provider, 104_233L, 113_000L), (job.BookingId, job.MerchantId, job.BookingNumber, job.FinalPricePaisa));
        Assert.Equal(0, BillingSubscriptions.Completed(Completed(new { bookingId = booking, providerId = provider, number = "PAO-x", totalPaisa = 1 })).BookingNumber);
    }

    [Fact]
    public void Tells_the_merchant_each_step_in_taka()
    {
        var p = new EventPayload(Completed(new { amountPaisa = 12_050, duePaisa = 60_000, blocked = true, reason = "wrong id" }));
        Assert.Equal(("due_limit_reached", "120.5", "600"), (BillingNotes.Notes[BillingEvents.CommissionCharged](p).Template,
            BillingNotes.Notes[BillingEvents.PaymentSubmitted](p).Data["amount"], BillingNotes.Notes[BillingEvents.PaymentConfirmed](p).Data["due"]));
        Assert.Equal("wrong id", BillingNotes.Notes[BillingEvents.PaymentRejected](p).Data["reason"]);
        var calm = new EventPayload(Completed(new { amountPaisa = 100 }));
        Assert.Equal("commission_charged", BillingNotes.Notes[BillingEvents.CommissionCharged](calm).Template);
        Assert.All(new[] { "commission_charged", "due_limit_reached", "payment_submitted", "payment_confirmed", "payment_rejected" },
            t => Assert.NotNull(NotificationTemplates.Render(t, "en", new Dictionary<string, string>())));
    }
}
