using Microsoft.EntityFrameworkCore;
using PAO.Core.Areas.Merchant.Services;
using PAO.EF;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.PerfSeed.Commands;

/// <summary>Puts a verified electrician online at `At` for the load test, without enrolment (`migrate perf-seed`).</summary>
public sealed record AddPerfMerchant(Guid MerchantId, GeoPoint At) : ICommand
{
    /// <summary>The seeded electrician service the merchants offer.</summary>
    public static readonly Guid ServiceId = SeedIds.For("service", "electrician");

    /// <summary>Its fan-install sub-service, which the load test books.</summary>
    public static readonly Guid SubServiceId = SeedIds.For("sub-service", "fan-install");
}

/// <summary>
/// Writes the merchant and their Level 1 straight into the provider and verification
/// schemas, as the Go and NestJS perf seeds did: enrolling thousands through the API would
/// dominate the run. The level row is plain SQL so Merchant takes no dependency on the
/// Verification area's code.
/// </summary>
public sealed class AddPerfMerchantHandler(PaoDbContext db, MerchantPresence presence) : IRequestHandler<AddPerfMerchant, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(AddPerfMerchant request, CancellationToken cancellationToken)
    {
        var (id, at) = (request.MerchantId, request.At);
        await db.Database.ExecuteSqlAsync($"""
            WITH p AS (
                INSERT INTO provider.providers (id, phone, full_name, gender, level, working_radius_m, rating_avg, rating_count,
                    home_base, created_at, updated_at)
                VALUES ({id}, '', 'Perf Provider', 'male', 1, 30000, 4.5, 10,
                    ST_SetSRID(ST_MakePoint({at.Lng}, {at.Lat}), 4326)::geography, now(), now()))
            INSERT INTO provider.provider_services (provider_id, service_id) VALUES ({id}, {AddPerfMerchant.ServiceId})
            """, cancellationToken);
        await db.Database.ExecuteSqlAsync($"INSERT INTO verification.levels (provider_id, level) VALUES ({id}, 1)", cancellationToken);
        await presence.GoOnline(id, at, cancellationToken);
        return Unit.Value;
    }
}
