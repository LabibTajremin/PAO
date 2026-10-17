namespace PAO.Lib.Areas.Notification;

/// <summary>Where a message is delivered.</summary>
public static class Channel
{
    /// <summary>The `"push"` value.</summary>
    public const string Push = "push";
    /// <summary>The `"sms"` value.</summary>
    public const string Sms = "sms";
    /// <summary>The `"inbox"` value.</summary>
    public const string Inbox = "inbox";
}

/// <summary>
/// A message to render in the recipient's language and deliver; delivery is idempotent per
/// (recipient, template, dedupe key).
/// </summary>
public sealed record NotificationMessage
{
    /// <summary>The recipient id.</summary>
    public required Guid RecipientId { get; init; }
    /// <summary>The app.</summary>
    public required string App { get; init; }
    /// <summary>The language.</summary>
    public required string Language { get; init; }
    /// <summary>The template.</summary>
    public required string Template { get; init; }
    /// <summary>The data.</summary>
    public required IReadOnlyDictionary<string, string> Data { get; init; }
    /// <summary>The booking id.</summary>
    public Guid? BookingId { get; init; }
    /// <summary>The channels.</summary>
    public required IReadOnlyList<string> Channels { get; init; }
    /// <summary>The dedupe key.</summary>
    public required string DedupeKey { get; init; }
}
