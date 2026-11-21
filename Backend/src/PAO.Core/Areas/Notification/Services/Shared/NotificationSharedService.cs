using PAO.Lib.Areas.Notification;

namespace PAO.Core.Areas.Notification.Services.Shared;

/// <summary>
/// The Notification contract for the other areas. Inbox and push are always used; SMS is
/// reserved for one-time codes, which Identity sends itself, so the channel list is not read.
/// </summary>
public sealed class NotificationSharedService(NotificationSender sender) : INotificationSharedService
{
    /// <inheritdoc />
    public Task Send(NotificationMessage message, CancellationToken cancellationToken) => sender.Send(
        new Outgoing(message.RecipientId, message.App, message.Template, message.Data, message.BookingId, message.DedupeKey, message.Language),
        cancellationToken);
}
