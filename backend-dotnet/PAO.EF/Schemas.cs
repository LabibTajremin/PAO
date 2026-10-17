namespace PAO.EF;

/// <summary>
/// The Postgres schema of each area, as the scripts in "DB Changes" create them. The
/// Merchant area keeps the `provider` schema so existing databases carry over.
/// </summary>
public static class Schemas
{
    public const string Identity = "identity";
    public const string Customer = "customer";
    public const string Merchant = "provider";
    public const string Verification = "verification";
    public const string Catalog = "catalog";
    public const string Booking = "booking";
    public const string Rating = "rating";
    public const string Notification = "notification";
    public const string Media = "media";
    public const string Admin = "admin";
    public const string Audit = "audit";
}
