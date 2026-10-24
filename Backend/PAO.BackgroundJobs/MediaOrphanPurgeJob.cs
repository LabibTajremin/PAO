using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Jobs;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mediator;

namespace PAO.BackgroundJobs;

/// <summary>Deletes uploads never attached to a record within 24 hours (daily 03:30 Asia/Dhaka, 02-architecture §9).</summary>
public sealed class MediaOrphanPurgeJob(IServiceScopeFactory scopes) : IScheduledJob
{
    /// <inheritdoc />
    public string Name => "media.purge_orphans";

    /// <inheritdoc />
    public JobSchedule Schedule { get; } = JobSchedule.DailyAt(3, 30);

    /// <inheritdoc />
    public async Task Run(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new PurgeOrphanMedia(), cancellationToken);
    }
}
