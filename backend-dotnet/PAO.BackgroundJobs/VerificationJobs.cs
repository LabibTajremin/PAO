using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Jobs;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.BackgroundJobs;

/// <summary>Runs one mediator request in its own scope, as each job run needs a fresh database context.</summary>
public abstract class MediatorJob<TResult>(IServiceScopeFactory scopes) : IScheduledJob
{
    /// <inheritdoc />
    public abstract string Name { get; }

    /// <inheritdoc />
    public abstract JobSchedule Schedule { get; }

    /// <summary>The request a run sends.</summary>
    protected abstract IRequest<TResult> Request { get; }

    /// <inheritdoc />
    public async Task Run(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(Request, cancellationToken);
    }
}

/// <summary>Expires approved documents past their date; levels drop (daily 02:00 Asia/Dhaka, PRD §6.4).</summary>
public sealed class ExpireDocumentsJob(IServiceScopeFactory scopes) : MediatorJob<int>(scopes)
{
    /// <inheritdoc />
    public override string Name => "verification.expire_documents";

    /// <inheritdoc />
    public override JobSchedule Schedule { get; } = JobSchedule.DailyAt(2, 0);

    /// <inheritdoc />
    protected override IRequest<int> Request => new ExpireDocuments();
}

/// <summary>Sends the 30, 7 and 1 day expiry reminders once each (daily 09:00 Asia/Dhaka, P-11).</summary>
public sealed class ExpiryRemindersJob(IServiceScopeFactory scopes) : MediatorJob<int>(scopes)
{
    /// <inheritdoc />
    public override string Name => "verification.expiry_reminders";

    /// <inheritdoc />
    public override JobSchedule Schedule { get; } = JobSchedule.DailyAt(9, 0);

    /// <inheritdoc />
    protected override IRequest<int> Request => new RemindExpiringDocuments();
}

/// <summary>Purges closed accounts' verification records and files after the retention period (daily 03:45 Asia/Dhaka, ADR-0023).</summary>
public sealed class PurgeClosedAccountsJob(IServiceScopeFactory scopes) : MediatorJob<int>(scopes)
{
    /// <inheritdoc />
    public override string Name => "verification.purge_closed";

    /// <inheritdoc />
    public override JobSchedule Schedule { get; } = JobSchedule.DailyAt(3, 45);

    /// <inheritdoc />
    protected override IRequest<int> Request => new PurgeClosedAccounts();
}
