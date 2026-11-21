using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Logging;
using Serilog;

namespace PAO.Infrastructure.Registration;

/// <summary>Reads and validates the configuration and sets up logging for a host.</summary>
public static class SettingsRegistration
{
    /// <summary>
    /// Adds `Config/*.json` and the environment to `builder`, validates the result (throwing
    /// <see cref="ConfigException"/> with every problem), wires Serilog for `host` (api,
    /// worker) and points Kestrel at HTTP_ADDR. Returns the validated settings.
    /// </summary>
    public static PaoSettings AddPaoSettings(this IHostApplicationBuilder builder, PaoPaths paths, IDictionary environment, string host)
    {
        builder.Configuration.AddPaoConfiguration(paths.Config, environment);
        var settings = ConfigValidator.Validate(PaoConfiguration.Bind(builder.Configuration));
        builder.Configuration["urls"] = ListenAddress.Parse(settings.Http.Address).ToUrl();
        builder.Services.AddSerilog(logger => LoggingSetup.Configure(logger, settings.Logging, host, paths.Home));
        builder.Services.AddSingleton(settings);
        return settings;
    }
}
