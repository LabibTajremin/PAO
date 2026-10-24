using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Jobs;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.BackgroundJobs;

/// <summary>
/// Times out requests past their accept deadline every 15 seconds (D12); a periodic sweep
/// rather than a job per booking, so a missed run catches up on the next one.
/// </summary>
public sealed class BookingExpiryJob(IServiceScopeFactory scopes) : IScheduledJob
{
    /// <inheritdoc />
    public string Name => "booking.expire_requests";

    /// <inheritdoc />
    public JobSchedule Schedule { get; } = JobSchedule.Every(TimeSpan.FromSeconds(15));

    /// <inheritdoc />
    public async Task Run(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new ExpireDueRequests(), cancellationToken);
    }
}
