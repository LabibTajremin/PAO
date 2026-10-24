using System.Collections;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Merchant.Features.PerfSeed.Commands;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Hosting;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>What the load-test scripts need to call the API as customers.</summary>
public sealed record PerfFixture(IReadOnlyList<string> Tokens, Guid ServiceId, Guid SubServiceId, double Lat, double Lng);

/// <summary>
/// `migrate perf-seed N`: puts N verified electricians online around Banani through the
/// Merchant area and prints customer tokens for the nearby-search load test (03-testing.md).
/// </summary>
public static class PerfSeedCommand
{
    /// <summary>Banani, Dhaka; the merchants spread around it.</summary>
    public static readonly GeoPoint Centre = new() { Lat = 23.7937, Lng = 90.4066 };

    private const int CustomerTokens = 50;

    /// <summary>Where the k-th of n merchants stands: a golden-angle spiral about 3 km across.</summary>
    public static GeoPoint SpiralPoint(int k, int n)
    {
        var r = 0.03 * Math.Sqrt((double)k / n);
        var a = k * 2.39996;
        return new GeoPoint { Lat = Centre.Lat + (r * Math.Sin(a)), Lng = Centre.Lng + (r * Math.Cos(a)) };
    }

    /// <summary>Seeds `n` merchants and writes the fixture as one JSON line; refuses production.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, int n, TextWriter output)
    {
        using var host = SeedCommand.BuildHost(paths, environment);
        var services = host.Services;
        if (services.GetRequiredService<PaoSettings>().App.Environment == AppEnvironments.Prod)
        {
            await output.WriteLineAsync("perf seed refuses to run in production");
            return 1;
        }
        for (var k = 0; k < n; k++)
        {
            // Each merchant is its own command and transaction, as NestJS seeded them one by one.
            await using var scope = services.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new AddPerfMerchant(Guid.NewGuid(), SpiralPoint(k, n)));
        }
        var ring = services.GetRequiredService<JwtKeyRing>();
        var signer = new TokenSigner(ring.Signing with { Ttl = TimeSpan.FromHours(2) }, services.GetRequiredService<IClock>(), services.GetRequiredService<IIdGenerator>());
        var tokens = Enumerable.Range(0, CustomerTokens)
            .Select(_ => signer.Sign(new TokenRequest(Guid.NewGuid().ToString(), ["customer"], Guid.NewGuid().ToString())).Token).ToList();
        var fixture = new PerfFixture(tokens, AddPerfMerchant.ServiceId, AddPerfMerchant.SubServiceId, Centre.Lat, Centre.Lng);
        await output.WriteLineAsync(JsonSerializer.Serialize(fixture, JsonSerializerOptions.Web));
        return 0;
    }
}
