namespace PAO.EF;

/// <summary>
/// The Postgres schema of each area, as the scripts in "DB Changes" create them. The
/// Merchant area keeps the `provider` schema so existing databases carry over.
/// </summary>
public static class Schemas
{
    /// <summary>The `"identity"` value.</summary>
    public const string Identity = "identity";
    /// <summary>The `"customer"` value.</summary>
    public const string Customer = "customer";
    /// <summary>The `"provider"` value.</summary>
    public const string Merchant = "provider";
    /// <summary>The `"verification"` value.</summary>
    public const string Verification = "verification";
    /// <summary>The `"catalog"` value.</summary>
    public const string Catalog = "catalog";
    /// <summary>The `"booking"` value.</summary>
    public const string Booking = "booking";
    /// <summary>The `"rating"` value.</summary>
    public const string Rating = "rating";
    /// <summary>The `"notification"` value.</summary>
    public const string Notification = "notification";
    /// <summary>The `"media"` value.</summary>
    public const string Media = "media";
    /// <summary>The `"admin"` value.</summary>
    public const string Admin = "admin";
    /// <summary>The `"audit"` value.</summary>
    public const string Audit = "audit";
}
