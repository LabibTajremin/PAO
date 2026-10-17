namespace PAO.Lib.Areas.Notification;

/// <summary>Where a message is delivered.</summary>
public static class Channel
{
    public const string Push = "push";
    public const string Sms = "sms";
    public const string Inbox = "inbox";
}

/// <summary>
/// A message to render in the recipient's language and deliver; delivery is idempotent per
/// (recipient, template, dedupe key).
/// </summary>
public sealed record NotificationMessage
{
    public required Guid RecipientId { get; init; }
    public required string App { get; init; }
    public required string Language { get; init; }
    public required string Template { get; init; }
    public required IReadOnlyDictionary<string, string> Data { get; init; }
    public Guid? BookingId { get; init; }
    public required IReadOnlyList<string> Channels { get; init; }
    public required string DedupeKey { get; init; }
}
