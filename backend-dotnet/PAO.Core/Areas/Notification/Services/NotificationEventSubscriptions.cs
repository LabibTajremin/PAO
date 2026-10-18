using PAO.Core.Areas.Notification.Repositories;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>
/// Notifies on every event that concerns someone; inbox rows are unique per event and
/// recipient, so redelivery neither duplicates nor re-pushes. Deleted accounts lose their
/// inbox and devices (PRD §11).
/// </summary>
public sealed class NotificationEventSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        foreach (var name in NotificationEventNotes.EventNames)
        {
            bus.Subscribe(name, "notification", async (envelope, cancellationToken) =>
            {
                await using var scope = scopes.CreateAsyncScope();
                await scope.ServiceProvider.GetRequiredService<NotificationEventNotes>().Handle(envelope, cancellationToken);
            });
        }
        bus.Subscribe(IdentityEvents.AccountDeleted, "notification", async (envelope, cancellationToken) =>
        {
            var account = Guid.Parse(new EventPayload(envelope).Id("accountId"));
            await using var scope = scopes.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<NotificationRepository>().Forget(account, cancellationToken);
        });
    }
}
