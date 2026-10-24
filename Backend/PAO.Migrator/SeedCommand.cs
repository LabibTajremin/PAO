using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.Core;
using PAO.Core.Areas.Catalog.Features.Seed.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Registration;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>
/// `migrate seed`: loads `Seed/catalog.yaml` idempotently through the areas that own the
/// data: the catalog through Catalog and, outside production and only with
/// SEED_ADMIN_PASSWORD set, the demo admins through Identity.
/// </summary>
public static class SeedCommand
{
    /// <summary>The seed file under the backend home.</summary>
    public static string CatalogFile(PaoPaths paths) => Path.Combine(paths.Home, "Seed", "catalog.yaml");

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
        var app = host.Services.GetRequiredService<PaoSettings>().App;
        if (app.Environment == AppEnvironments.Prod || app.SeedAdminPassword.Length == 0)
        {
            return 0;
        }
        foreach (var admin in admins)
        {
            // One scope per admin: each is its own command, as NestJS ensured them one by one.
            await using var scope = host.Services.CreateAsyncScope();
            await scope.ServiceProvider.GetRequiredService<IMediator>()
                .Send(new EnsureSeedAdminCommand(admin.Email, admin.Name, admin.Roles, app.SeedAdminPassword));
        }
        await output.WriteLineAsync($"migrate seed: {admins.Count} admins");
        return 0;
    }
}
