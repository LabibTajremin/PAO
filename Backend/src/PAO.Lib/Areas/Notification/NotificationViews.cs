using System.Text.Json.Serialization;

namespace PAO.Lib.Areas.Notification;

/// <summary>The two apps; device tokens and inboxes are kept per app.</summary>
public static class NotificationApp
{
    /// <summary>The customer app.</summary>
    public const string Customer = "customer";
    /// <summary>The partner app (the merchant's app).</summary>
    public const string Partner = "partner";

    /// <summary>Reports whether `app` names one of the two apps.</summary>
    public static bool IsApp(string app) => app is Customer or Partner;
}

/// <summary>Reasons the notification use cases raise.</summary>
public static class NotificationReasons
{
    /// <summary>No such notification for this recipient and app.</summary>
    public const string NotFound = "notification.not_found";
    /// <summary>Unknown template or app, or no dedupe key.</summary>
    public const string Invalid = "notification.invalid";
}

/// <summary>One inbox entry as the area's services see it.</summary>
public sealed record InboxItem
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The template that produced it.</summary>
    public required string Type { get; init; }
    /// <summary>The title.</summary>
    public required string Title { get; init; }
    /// <summary>The body.</summary>
    public required string Body { get; init; }
    /// <summary>The booking it is about.</summary>
    public Guid? BookingId { get; init; }
    /// <summary>Whether read.</summary>
    public required bool Read { get; init; }
    /// <summary>When it was stored.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>The API shape of a notification.</summary>
public sealed record NotificationView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The template that produced it.</summary>
    public required string Type { get; init; }
    /// <summary>The title.</summary>
    public required string Title { get; init; }
    /// <summary>The body.</summary>
    public required string Body { get; init; }
    /// <summary>The booking it is about; absent when none.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? BookingId { get; init; }
    /// <summary>Whether read.</summary>
    public required bool Read { get; init; }
    /// <summary>When it was stored (ISO 8601).</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The API shape of an inbox page.</summary>
public sealed record NotificationListView
{
    /// <summary>The page, newest first.</summary>
    public required IReadOnlyList<NotificationView> Items { get; init; }
    /// <summary>How many are unread in the app.</summary>
    public required int UnreadCount { get; init; }
    /// <summary>The cursor of the next page; absent on the last.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The body of registerCustomerDeviceToken and registerProviderDeviceToken.</summary>
public sealed record DeviceTokenInput
{
    /// <summary>The push token.</summary>
    public required string Token { get; init; }
    /// <summary>`android`, `ios` or `web`.</summary>
    public required string Platform { get; init; }
}
