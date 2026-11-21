using PAO.Core.Areas.Merchant.Repositories;
using PAO.Core.Areas.Merchant.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.Presence.Commands;

/// <summary>Puts a verified merchant online at their position (PRD §6.1).</summary>
public sealed record GoOnline(Guid MerchantId, GeoPoint At) : ICommand<PresenceStateView>;

/// <summary>Refreshes an online merchant's position every 30 seconds.</summary>
public sealed record SendHeartbeat(Guid MerchantId, GeoPoint At) : ICommand<PresenceStateView>;

/// <summary>Takes the merchant offline; their position stops being stored (PRD §11).</summary>
public sealed record GoOffline(Guid MerchantId) : ICommand<PresenceStateView>;

/// <summary>The presence state with the heartbeat interval the app keeps.</summary>
public static class PresenceStates
{
    /// <summary>The view for `online`.</summary>
    public static PresenceStateView Of(bool online) => new() { Online = online, HeartbeatIntervalSeconds = MerchantRules.HeartbeatEverySeconds };
}

/// <summary>Answers <see cref="GoOnline"/>.</summary>
public sealed class GoOnlineHandler(MerchantPresence presence) : IRequestHandler<GoOnline, PresenceStateView>
{
    /// <inheritdoc />
    public async Task<PresenceStateView> Handle(GoOnline request, CancellationToken cancellationToken)
    {
        await presence.GoOnline(request.MerchantId, request.At, cancellationToken);
        return PresenceStates.Of(true);
    }
}

/// <summary>Answers <see cref="SendHeartbeat"/>.</summary>
public sealed class SendHeartbeatHandler(MerchantPresence presence) : IRequestHandler<SendHeartbeat, PresenceStateView>
{
    /// <inheritdoc />
    public async Task<PresenceStateView> Handle(SendHeartbeat request, CancellationToken cancellationToken)
    {
        await presence.Heartbeat(request.MerchantId, request.At, cancellationToken);
        return PresenceStates.Of(true);
    }
}

/// <summary>Answers <see cref="GoOffline"/>.</summary>
public sealed class GoOfflineHandler(MerchantPresence presence) : IRequestHandler<GoOffline, PresenceStateView>
{
    /// <inheritdoc />
    public async Task<PresenceStateView> Handle(GoOffline request, CancellationToken cancellationToken)
    {
        await presence.GoOffline(request.MerchantId, "provider", cancellationToken);
        return PresenceStates.Of(false);
    }
}

/// <summary>Answers <see cref="ReapLostPresence"/>; one lookup for every lapsed merchant's services.</summary>
public sealed class ReapLostPresenceHandler(IPresence presence, MerchantRepository repository) : IRequestHandler<ReapLostPresence, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(ReapLostPresence request, CancellationToken cancellationToken)
    {
        var lost = await presence.Lost();
        var services = await repository.ServicesOfExisting(lost, cancellationToken);
        foreach (var id in lost)
        {
            await presence.Offline(id, services.GetValueOrDefault(id, []));
            if (services.ContainsKey(id))
            {
                await repository.Publish(id, new ProviderWentOffline { ProviderId = id, Reason = "heartbeat_lost" }, cancellationToken);
            }
        }
        return Unit.Value;
    }
}
