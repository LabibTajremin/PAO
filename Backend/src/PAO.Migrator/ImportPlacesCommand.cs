using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Customer.Features.Places.Commands;
using PAO.Infrastructure.Hosting;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>
/// `migrate import-places FILE`: replaces the Dhaka places with an `osmium export -f
/// geojsonseq` file built by `tools/places/build.sh` (ADR-0042). The file is streamed, so a
/// city-sized extract never sits in memory at once.
/// </summary>
public static class ImportPlacesCommand
{
    /// <summary>Imports `rest[0]` with the configuration of `environment`; returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, string[] rest, TextWriter output)
    {
        if (rest.Length != 1 || !File.Exists(rest[0]))
        {
            await output.WriteLineAsync("usage: migrate import-places FILE (a GeoJSON-sequence file from tools/places/build.sh)");
            return 2;
        }
        using var host = SeedCommand.BuildHost(paths, environment);
        await using var scope = host.Services.CreateAsyncScope();
        var count = await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new ImportPlaces(File.ReadLines(rest[0])));
        await output.WriteLineAsync($"migrate import-places: {count} places");
        return 0;
    }
}
