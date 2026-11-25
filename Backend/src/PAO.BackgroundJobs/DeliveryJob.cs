using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Jobs;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.BackgroundJobs;

/// <summary>
/// Makes the dates whose cutoff passed into accepted bookings every five minutes (ADR-0041 §4);
/// a missed run catches up while the delivery window is still ahead.
/// </summary>
public sealed class MaterialiseDeliveriesJob(IServiceScopeFactory scopes) : MediatorJob<int>(scopes)
{
    /// <inheritdoc />
    public override string Name => "booking.materialise_deliveries";

    /// <inheritdoc />
    public override JobSchedule Schedule { get; } = JobSchedule.Every(TimeSpan.FromMinutes(5));

    /// <inheritdoc />
    protected override IRequest<int> Request => new MaterialiseDeliveries();
}
