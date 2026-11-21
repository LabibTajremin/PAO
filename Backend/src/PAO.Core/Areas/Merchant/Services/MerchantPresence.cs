using PAO.Core.Areas.Merchant.Repositories;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>Online, heartbeat and offline for merchants (PRD §6.1, §11).</summary>
public sealed class MerchantPresence(MerchantRepository repository, IPresence presence)
{
    /// <summary>Puts a verified merchant into the presence index at their position.</summary>
    public async Task GoOnline(Guid id, GeoPoint at, CancellationToken cancellationToken)
    {
        var m = await repository.Get(id, cancellationToken);
        if (MerchantRules.CannotGoOnline(m) is { } refusal)
        {
            throw new DomainException(refusal);
        }
        await presence.Online(id, m.ServiceIds, at);
    }

    /// <summary>Refreshes an online merchant's position; `provider.offline` otherwise.</summary>
    public async Task Heartbeat(Guid id, GeoPoint at, CancellationToken cancellationToken)
    {
        var m = await repository.Get(id, cancellationToken);
        await presence.Beat(id, m.ServiceIds, at);
    }

    /// <summary>Removes the merchant from presence, dropping their position, and publishes `ProviderWentOffline`.</summary>
    public async Task GoOffline(Guid id, string reason, CancellationToken cancellationToken)
    {
        var m = await repository.Get(id, cancellationToken);
        await presence.Offline(id, m.ServiceIds);
        await repository.Publish(id, new ProviderWentOffline { ProviderId = id, Reason = reason }, cancellationToken);
    }

    /// <summary>Reports whether the merchant is online now.</summary>
    public async Task<bool> IsAvailable(Guid id) => (await presence.OnlineAmong([id])).Contains(id);
}
