using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.Core;
using PAO.Core.Areas.Admin.Features.Appearance.Commands;
using PAO.Core.Areas.Catalog.Features.Seed.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Registration;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;
using PAO.Infrastructure.Storage;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>
/// `migrate seed`: loads `database/seed/catalog.yaml` idempotently through the areas that own the
/// data: the catalog through Catalog and, outside production and only with
/// SEED_ADMIN_PASSWORD set, the demo admins through Identity.
/// </summary>
public static class SeedCommand
{
    /// <summary>The seed file under the backend home.</summary>
    public static string CatalogFile(PaoPaths paths) => Path.Combine(paths.Home, "database", "seed", "catalog.yaml");

    /// <summary>The seed illustrations, one `&lt;slot&gt;.svg` per artwork slot (ADR-0040).</summary>
    public static string ArtworkFolder(PaoPaths paths) => Path.Combine(paths.Home, "database", "seed", "artwork");

    /// <summary>A host with every area, configured from `environment`, for the seed commands.</summary>
    public static IHost BuildHost(PaoPaths paths, IDictionary environment)
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
        return builder.Build();
    }

    /// <summary>Seeds with the configuration of `environment`; returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, TextWriter output)
    {
        using var host = BuildHost(paths, environment);
        var (categories, admins) = SeedFile.Parse(await File.ReadAllTextAsync(CatalogFile(paths)));
        await using (var scope = host.Services.CreateAsyncScope())
        {
            await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new SeedCatalog(categories));
        }
        await output.WriteLineAsync($"migrate seed: {categories.Count} categories");
        await output.WriteLineAsync($"migrate seed: {await SeedArtwork(host, paths)} artwork slots");
        var app = host.Services.GetRequiredService<PaoSettings>().App;
        if (app.Environment == AppEnvironments.Prod || app.SeedAdminPassword.Length == 0)
        {
            return 0;
        }
        foreach (var admin in admins)
        {
            // One scope per admin: each is its own command, ensured one by one.
            await using var scope = host.Services.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<IMediator>()
                .Send(new EnsureSeedAdminCommand(admin.Email, admin.Name, admin.Roles, app.SeedAdminPassword));
        }
        await output.WriteLineAsync($"migrate seed: {admins.Count} admins");
        return 0;
    }

    // The migrator runs before the API, so the public bucket and its read policy may not exist yet.
    private static async Task<int> SeedArtwork(IHost host, PaoPaths paths)
    {
        var storage = host.Services.GetRequiredService<PaoSettings>().Storage;
        var store = host.Services.GetRequiredService<ObjectStore>();
        await store.EnsureBucket(storage.BucketPublic, CancellationToken.None);
        if (storage.PublicReadPolicy)
        {
            await store.AllowPublicRead(storage.BucketPublic, CancellationToken.None);
        }
        await using var scope = host.Services.CreateAsyncScope();
        return await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new SeedArtwork(ArtworkFolder(paths)));
    }
}
