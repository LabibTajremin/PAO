using PAO.Core.Areas.Notification.Repositories;
using PAO.EF.Notification;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Push;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>Asks for one notification in one app; `Language` "en" or anything else for Bangla.</summary>
public sealed record Outgoing(
    Guid Recipient, string App, string Template, IReadOnlyDictionary<string, string> Data, Guid? BookingId, string DedupeKey, string Language);

/// <summary>
/// Stores a message in the inbox and pushes it to the recipient's devices (C-13, P-12). A
/// message seen before is skipped entirely, so it is neither stored nor pushed twice.
/// </summary>
public sealed class NotificationSender(NotificationRepository repository, IPushSender pusher, IClock clock, IIdGenerator ids, ILogger<NotificationSender> logger)
{
    /// <summary>Renders, stores and pushes `m`; throws `notification.invalid` for an unknown template or app or an empty dedupe key.</summary>
    public async Task Send(Outgoing m, CancellationToken cancellationToken)
    {
        var text = NotificationTemplates.Render(m.Template, m.Language, m.Data);
        if (text is null || m.DedupeKey.Length == 0 || !NotificationApp.IsApp(m.App))
        {
            throw new DomainException(NotificationReasons.Invalid);
        }
        var fresh = await repository.Add(new NotificationRecord
        {
            Id = ids.NewId(),
            RecipientId = m.Recipient,
            App = m.App,
            Type = m.Template,
            Title = text.Title,
            Body = text.Body,
            BookingId = m.BookingId,
            DedupeKey = m.DedupeKey,
            CreatedAt = clock.Now,
        }, cancellationToken);
        if (!fresh)
        {
            return;
        }
        var data = new Dictionary<string, string> { ["type"] = m.Template };
        if (m.BookingId is { } booking)
        {
            data["bookingId"] = booking.ToString();
        }
        var push = new PushMessage(text.Title, text.Body, data);
        foreach (var token in await repository.Tokens(m.Recipient, m.App, cancellationToken))
        {
            await PushOne(token, push, cancellationToken);
        }
    }

    // Push failures are logged, not thrown: the inbox entry is the record, and retrying the
    // event would not fix a device.
    private async Task PushOne(string token, PushMessage push, CancellationToken cancellationToken)
    {
        try
        {
            await pusher.Push(token, push, cancellationToken);
        }
        catch (InvalidPushTokenException)
        {
            await repository.DropToken(token, cancellationToken);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "push failed");
        }
    }
}
