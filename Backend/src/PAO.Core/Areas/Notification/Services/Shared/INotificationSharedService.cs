using PAO.Lib.Areas.Notification;

namespace PAO.Core.Areas.Notification.Services.Shared;

/// <summary>
/// What other areas may ask of the Notification area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface INotificationSharedService
{
    /// <summary>Renders a template in the recipient's language and delivers it on the requested channels; idempotent per (recipient, template, dedupe key).</summary>
    Task Send(NotificationMessage message, CancellationToken cancellationToken);
}
