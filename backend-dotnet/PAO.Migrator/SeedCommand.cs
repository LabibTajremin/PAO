using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.Core;
using PAO.Core.Areas.Catalog.Features.Seed.Commands;
using PAO.Core.Registration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>
/// `migrate seed`: loads `Seed/catalog.yaml` idempotently through the areas that own the
/// data. The catalog is seeded here; the file's demo admins belong to Identity, which seeds
/// them once its admin seeding is ported (it reads the same file).
/// </summary>
public static class SeedCommand
{
    /// <summary>The seed file under the backend home.</summary>
    public static string CatalogFile(PaoPaths paths) => Path.Combine(paths.Home, "Seed", "catalog.yaml");

    /// <summary>Seeds with the configuration of `environment`; returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, TextWriter output)
    {
        var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { ContentRootPath = paths.BaseDirectory });
        var settings = builder.AddPaoSettings(paths, environment, "migrate");
        settings.Logging.WriteFiles = false;
        builder.Services
            .AddBuiltInServices(settings)
            .AddCustomServices(settings, typeof(ApiHost).Assembly)
            .AddDatabase(settings)
            .AddRepositories()
            .AddAreas();
        using var host = builder.Build();
        var (categories, _) = SeedFile.Parse(await File.ReadAllTextAsync(CatalogFile(paths)));
        await using var scope = host.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new SeedCatalog(categories));
        await output.WriteLineAsync($"migrate seed: {categories.Count} categories");
        return 0;
    }
}
