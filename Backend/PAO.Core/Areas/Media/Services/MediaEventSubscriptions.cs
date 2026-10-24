using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Media.Services;

/// <summary>Erasure: a deleted account's own files go at once; its documents wait for the retention purge.</summary>
public sealed class MediaEventSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus) => bus.Subscribe(IdentityEvents.AccountDeleted, "media", async (envelope, cancellationToken) =>
    {
        var account = Guid.Parse(new EventPayload(envelope).Id("accountId"));
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new DeleteAccountMedia(account), cancellationToken);
    });
}
