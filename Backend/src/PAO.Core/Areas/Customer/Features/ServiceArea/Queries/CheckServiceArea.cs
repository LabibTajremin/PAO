using PAO.Core.Areas.Customer.Services;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.ServiceArea.Queries;

/// <summary>Reports whether a point lies inside the launch area (C35).</summary>
public sealed record CheckServiceArea(GeoPoint Point) : IQuery<ServiceAreaCheckView>;

/// <summary>Answers <see cref="CheckServiceArea"/> from the admin setting.</summary>
public sealed class CheckServiceAreaHandler(CustomerPeers peers) : IRequestHandler<CheckServiceArea, ServiceAreaCheckView>
{
    /// <inheritdoc />
    public async Task<ServiceAreaCheckView> Handle(CheckServiceArea request, CancellationToken cancellationToken) =>
        new() { Covered = LaunchArea.Covers(await peers.LaunchAreaGeoJson(cancellationToken), request.Point) };
}
