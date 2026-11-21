using PAO.Core.Areas.Notification.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Notification.Features.Inbox.Commands;

/// <summary>Marks one of the recipient's notifications in an app read; `notification.not_found` otherwise.</summary>
public sealed record MarkNotificationRead(Guid Recipient, string App, Guid NotificationId) : ICommand;

/// <summary>Marks every notification of the recipient in an app read.</summary>
public sealed record MarkAllNotificationsRead(Guid Recipient, string App) : ICommand;

/// <summary>Answers <see cref="MarkNotificationRead"/>.</summary>
public sealed class MarkNotificationReadHandler(NotificationRepository repository, IClock clock) : IRequestHandler<MarkNotificationRead, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(MarkNotificationRead request, CancellationToken cancellationToken)
    {
        await repository.MarkRead(request.Recipient, request.App, request.NotificationId, clock.Now, cancellationToken);
        return Unit.Value;
    }
}

/// <summary>Answers <see cref="MarkAllNotificationsRead"/>.</summary>
public sealed class MarkAllNotificationsReadHandler(NotificationRepository repository, IClock clock) : IRequestHandler<MarkAllNotificationsRead, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(MarkAllNotificationsRead request, CancellationToken cancellationToken)
    {
        await repository.MarkAllRead(request.Recipient, request.App, clock.Now, cancellationToken);
        return Unit.Value;
    }
}
