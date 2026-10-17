using System.Collections;
using Microsoft.Extensions.Configuration;

namespace PAO.Infrastructure.Configuration;

/// <summary>
/// Builds the configuration every host reads: the defaults in `Config/*.json`, then
/// `Section__Key` environment variables, then the NestJS variable names (secrets only
/// ever come from the environment).
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
        builder.AddEnvironmentVariables();
        builder.AddInMemoryCollection(LegacyEnvironment.Map(environment));
        return builder;
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
    public required AppOptions App { get; init; }
    public required DatabaseOptions Database { get; init; }
    public required RedisOptions Redis { get; init; }
    public required JwtOptions Jwt { get; init; }
    public required LoggingOptions Logging { get; init; }
    public required SmtpOptions Smtp { get; init; }
    public required StorageOptions Storage { get; init; }
    public required SmsOptions Sms { get; init; }
    public required PushOptions Push { get; init; }
    public required JobsOptions Jobs { get; init; }
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
