namespace PAO.Infrastructure.Push;

/// <summary>
/// The Android notification channels the apps create at start (P18). Each is high importance,
/// because FCM's fallback "Miscellaneous" channel never shows a heads-up banner.
/// </summary>
public static class PushChannels
{
    /// <summary>Booking and job status, new requests.</summary>
    public const string Bookings = "pao_bookings";

    /// <summary>Billing and verification.</summary>
    public const string Account = "pao_account";

    /// <summary>Everything else, such as admin broadcasts.</summary>
    public const string General = "pao_general";

    private static readonly IReadOnlyDictionary<string, string> ByType = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["booking_requested"] = Bookings,
        ["booking_accepted"] = Bookings,
        ["booking_rejected"] = Bookings,
        ["booking_timed_out"] = Bookings,
        ["request_missed"] = Bookings,
        ["provider_on_the_way"] = Bookings,
        ["provider_arrived"] = Bookings,
        ["booking_started"] = Bookings,
        ["extras_proposed"] = Bookings,
        ["extras_decided"] = Bookings,
        ["booking_completed"] = Bookings,
        ["booking_cancelled"] = Bookings,
        ["subscription_requested"] = Bookings,
        ["subscription_accepted"] = Bookings,
        ["subscription_declined"] = Bookings,
        ["subscription_changed"] = Bookings,
        ["delivery_changed"] = Bookings,
        ["delivery_declined"] = Bookings,
        ["delivery_tomorrow"] = Bookings,
        ["deliveries_tomorrow"] = Bookings,
        ["level_changed"] = Account,
        ["document_rejected"] = Account,
        ["document_expired"] = Account,
        ["document_expiring"] = Account,
        ["level2_scheduled"] = Account,
        ["commission_charged"] = Account,
        ["due_limit_reached"] = Account,
        ["payment_submitted"] = Account,
        ["payment_confirmed"] = Account,
        ["payment_rejected"] = Account,
        ["complaint_resolved"] = Account,
    };

    /// <summary>The channel of a notification type; unknown or missing types go to <see cref="General"/>.</summary>
    public static string For(string? type) => type is not null && ByType.TryGetValue(type, out var channel) ? channel : General;

    /// <summary>
    /// The iOS interruption level: booking events break through Focus as time sensitive,
    /// the rest are ordinary alerts.
    /// </summary>
    public static string InterruptionLevel(string channel) => channel == Bookings ? "time-sensitive" : "active";
}
