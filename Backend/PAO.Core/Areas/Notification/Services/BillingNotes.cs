using System.Globalization;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Billing;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>What the merchant hears at each step of their dues (ADR-0035 §3, §4).</summary>
public static class BillingNotes
{
    /// <summary>The template and its values for each Billing event, by event name.</summary>
    public static readonly IReadOnlyDictionary<string, Func<EventPayload, (string Template, Dictionary<string, string> Data)>> Notes =
        new Dictionary<string, Func<EventPayload, (string, Dictionary<string, string>)>>(StringComparer.Ordinal)
        {
            // A commission that crosses the limit says so, because the merchant can no longer accept.
            [BillingEvents.CommissionCharged] = p => (p.Flag("blocked") ? "due_limit_reached" : "commission_charged", Amounts(p)),
            [BillingEvents.PaymentSubmitted] = p => ("payment_submitted", Amounts(p)),
            [BillingEvents.PaymentConfirmed] = p => ("payment_confirmed", Amounts(p)),
            [BillingEvents.PaymentRejected] = p => ("payment_rejected", new(Amounts(p)) { ["reason"] = p.Text("reason") }),
        };

    private static Dictionary<string, string> Amounts(EventPayload p) => new()
    {
        ["amount"] = Taka(p.Number("amountPaisa")),
        ["due"] = Taka(p.Number("duePaisa")),
    };

    /// <summary>Paisa as taka with up to two decimals, e.g. 12050 → "120.5".</summary>
    public static string Taka(double paisa) => (paisa / 100).ToString("0.##", CultureInfo.InvariantCulture);
}
