using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Dashboard.Queries;

/// <summary>The admin home numbers (A-09), cached for a minute under `cache:dashboard`: a minute-old count is fine.</summary>
public sealed record GetDashboard : IQuery<DashboardView>;

/// <summary>Checks <see cref="GetDashboard"/>.</summary>
public sealed class GetDashboardValidator : AbstractValidator<GetDashboard>
{
    /// <summary>Nothing to check.</summary>
    public GetDashboardValidator() => RuleFor(r => r).NotNull();
}

/// <summary>Answers <see cref="GetDashboard"/>; a cache outage only costs a rebuild.</summary>
public sealed class GetDashboardHandler(DashboardRepository repository, AdminPeers peers, JsonCache cache, RedisKeys keys, IClock clock, ILogger<GetDashboardHandler> logger)
    : IRequestHandler<GetDashboard, DashboardView>
{
    private static readonly TimeSpan Ttl = TimeSpan.FromMinutes(1);

    /// <inheritdoc />
    public async Task<DashboardView> Handle(GetDashboard request, CancellationToken cancellationToken)
    {
        var key = keys.Key("cache", "dashboard");
        try
        {
            if (await cache.Get<DashboardView>(key) is { } cached)
            {
                return cached;
            }
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "dashboard cache read failed");
        }
        var today = DateOnly.FromDateTime(clock.Now.ToOffset(DhakaTime.Offset).DateTime);
        var counts = await repository.Counts(today.AddDays(1 - AdminRules.DashboardDays), cancellationToken);
        var pending = await peers.Verification.CountPendingReviews(cancellationToken);
        var (days, rate) = AdminRules.FillDays(today, counts.Days);
        var view = new DashboardView
        {
            ProvidersByStatus = counts.ProvidersByStatus,
            ProvidersByLevel = counts.ProvidersByLevel,
            BookingsPerDay = [.. days.Select(d => new DayCountView { Date = d.Date, Total = d.Total, Completed = d.Completed })],
            CompletionRate = rate,
            OpenComplaints = counts.OpenComplaints,
            PendingVerifications = pending,
            GeneratedAt = IsoTime.Format(clock.Now),
        };
        try
        {
            await cache.Set(key, view, Ttl);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "dashboard cache write failed");
        }
        return view;
    }
}
