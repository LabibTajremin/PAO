using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Jobs;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.BackgroundJobs;

/// <summary>Takes merchants whose heartbeat lapsed offline, every minute (PRD §6.1).</summary>
public sealed class MerchantPresenceReapJob(IServiceScopeFactory scopes) : IScheduledJob
{
    /// <inheritdoc />
    public string Name => "provider.reap_lost_presence";

    /// <inheritdoc />
    public JobSchedule Schedule { get; } = JobSchedule.Every(TimeSpan.FromMinutes(1));

    /// <inheritdoc />
    public async Task Run(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new ReapLostPresence(), cancellationToken);
    }
}
