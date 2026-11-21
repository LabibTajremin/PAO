namespace PAO.Core.Areas.Billing.Services;

/// <summary>The money rules of ADR-0035.</summary>
public static class BillingRules
{
    /// <summary>The payment methods a merchant may report (ADR-0035 §4).</summary>
    public static readonly IReadOnlySet<string> Methods = new HashSet<string>(StringComparer.Ordinal) { "cash_to_agent", "bkash", "nagad", "bank" };

    /// <summary>
    /// PAO's commission on a final price, in paisa: `rateBp` basis points rounded half up
    /// (ADR-0035 §2, E9). A free job or a negative total earns nothing.
    /// </summary>
    public static long Commission(long totalPaisa, int rateBp) =>
        totalPaisa <= 0 || rateBp <= 0 ? 0 : ((totalPaisa * rateBp) + 5_000) / 10_000;
}
