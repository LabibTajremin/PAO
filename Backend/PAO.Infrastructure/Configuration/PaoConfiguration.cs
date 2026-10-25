using System.Collections;
using Microsoft.Extensions.Configuration;

namespace PAO.Infrastructure.Configuration;

/// <summary>
/// Builds the configuration every host reads: the defaults in `Config/*.json`, then a
/// developer's `appsettings.Local.json` (never in staging or prod), then `Section__Key`
/// environment variables, then the NestJS variable names (shared deployments take secrets
/// only from the environment).
/// </summary>
public static class PaoConfiguration
{
    /// <summary>Adds the config files of `configDirectory` and the environment.</summary>
    public static IConfigurationBuilder AddPaoConfiguration(
        this IConfigurationBuilder builder, string configDirectory, IDictionary environment)
    {
        if (!Directory.Exists(configDirectory))
        {
            throw new DirectoryNotFoundException($"config directory {configDirectory} not found");
        }
        foreach (var file in Directory.GetFiles(configDirectory, "*.json").Order(StringComparer.Ordinal))
        {
            builder.AddJsonFile(file, optional: false, reloadOnChange: false);
        }
        AddLocalFile(builder, configDirectory, environment);
        builder.AddEnvironmentVariables();
        builder.AddInMemoryCollection(LegacyEnvironment.Map(environment));
        return builder;
    }

    /// <summary>The git-ignored developer file next to `Config/`, copied from `appsettings.Local.example.json`.</summary>
    public const string LocalFileName = "appsettings.Local.json";

    private static readonly string[] SharedEnvironments = ["staging", "prod"];

    private static void AddLocalFile(IConfigurationBuilder builder, string configDirectory, IDictionary environment)
    {
        var file = Path.Combine(Path.GetDirectoryName(Path.GetFullPath(configDirectory))!, LocalFileName);
        // The file holds public demo keys; a shared deployment must fail on a missing secret, not run on them.
        var appEnv = (environment["APP_ENV"] ?? environment["App__Environment"]) as string;
        if (File.Exists(file) && !SharedEnvironments.Contains(appEnv?.Trim().ToLowerInvariant()))
        {
            builder.AddJsonFile(file, optional: false, reloadOnChange: false);
        }
    }

    /// <summary>Binds every section; values the files and environment leave out keep their defaults.</summary>
    public static PaoSettings Bind(IConfiguration configuration) => new()
    {
        App = Section<AppOptions>(configuration, AppOptions.Section),
        Database = Section<DatabaseOptions>(configuration, DatabaseOptions.Section),
        Redis = Section<RedisOptions>(configuration, RedisOptions.Section),
        Jwt = Section<JwtOptions>(configuration, JwtOptions.Section),
        Logging = Section<LoggingOptions>(configuration, LoggingOptions.Section),
        Smtp = Section<SmtpOptions>(configuration, SmtpOptions.Section),
        Storage = Section<StorageOptions>(configuration, StorageOptions.Section),
        Sms = Section<SmsOptions>(configuration, SmsOptions.Section),
        Push = Section<PushOptions>(configuration, PushOptions.Section),
        Jobs = Section<JobsOptions>(configuration, JobsOptions.Section),
        Http = Section<HttpOptions>(configuration, HttpOptions.Section),
    };

    private static T Section<T>(IConfiguration configuration, string name)
        where T : new()
    {
        var options = new T();
        configuration.GetSection(name).Bind(options);
        return options;
    }
}

/// <summary>Every configuration section, bound.</summary>
public sealed record PaoSettings
{
    /// <summary>The app.</summary>
    public required AppOptions App { get; init; }
    /// <summary>The database.</summary>
    public required DatabaseOptions Database { get; init; }
    /// <summary>The redis.</summary>
    public required RedisOptions Redis { get; init; }
    /// <summary>The jwt.</summary>
    public required JwtOptions Jwt { get; init; }
    /// <summary>The logging.</summary>
    public required LoggingOptions Logging { get; init; }
    /// <summary>The smtp.</summary>
    public required SmtpOptions Smtp { get; init; }
    /// <summary>The storage.</summary>
    public required StorageOptions Storage { get; init; }
    /// <summary>The sms.</summary>
    public required SmsOptions Sms { get; init; }
    /// <summary>The push.</summary>
    public required PushOptions Push { get; init; }
    /// <summary>The jobs.</summary>
    public required JobsOptions Jobs { get; init; }
    /// <summary>The http.</summary>
    public required HttpOptions Http { get; init; }

    /// <summary>The fields safe to log at start; secrets never appear.</summary>
    public IReadOnlyDictionary<string, string> LogFields() => new Dictionary<string, string>
    {
        ["app_env"] = App.Environment,
        ["http_addr"] = Http.Address,
        ["sms_adapter"] = Sms.Adapter,
        ["push_adapter"] = Push.Adapter,
        ["jwt_key_id"] = Jwt.KeyId,
    };
}
