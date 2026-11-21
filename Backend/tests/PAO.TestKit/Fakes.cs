using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;

namespace PAO.TestKit;

/// <summary>A clock tests move by hand.</summary>
public sealed class FakeClock(DateTimeOffset now) : IClock
{
    /// <inheritdoc />
    public DateTimeOffset Now { get; set; } = now;

    /// <summary>Moves the clock forward.</summary>
    public void Advance(TimeSpan by) => Now += by;
}

/// <summary>Returns the given ids in order, then fresh UUIDv7 values.</summary>
public sealed class SequenceIds(params Guid[] ids) : IIdGenerator
{
    private int next;

    /// <inheritdoc />
    public Guid NewId() => next < ids.Length ? ids[next++] : Guid.CreateVersion7();
}

/// <summary>Settings for tests: valid keys, the provided services, a private Redis environment.</summary>
public static class TestSettings
{
    /// <summary>Complete settings; `databaseUrl` defaults to the provided server.</summary>
    public static PaoSettings Create(string? databaseUrl = null, string appEnv = AppEnvironments.Test) => new()
    {
        App = new AppOptions { Environment = appEnv, DataEncryptionKey = TestEnvironment.Key },
        Database = new DatabaseOptions { Url = databaseUrl ?? TestEnvironment.DatabaseUrl },
        Redis = new RedisOptions { Url = TestEnvironment.RedisUrl },
        Jwt = new JwtOptions { SigningKey = TestEnvironment.Key },
        Logging = new LoggingOptions { WriteFiles = false },
        Smtp = new SmtpOptions(),
        Storage = new StorageOptions
        {
            Endpoint = TestEnvironment.S3Endpoint,
            AccessKey = TestEnvironment.S3AccessKey,
            SecretKey = TestEnvironment.S3SecretKey,
            BucketPrivate = "pao-net-test-private",
            BucketPublic = "pao-net-test-public",
        },
        Sms = new SmsOptions(),
        Push = new PushOptions(),
        Jobs = new JobsOptions(),
        Http = new HttpOptions { Address = "127.0.0.1:0", MetricsAddress = "127.0.0.1:0" },
    };

    /// <summary>The environment variables that produce settings like <see cref="Create"/>.</summary>
    public static Dictionary<string, string> Environment(string databaseUrl, string appEnv = AppEnvironments.Test) => new()
    {
        ["APP_ENV"] = appEnv,
        ["DATABASE_URL"] = databaseUrl,
        ["REDIS_URL"] = TestEnvironment.RedisUrl,
        ["S3_ENDPOINT"] = TestEnvironment.S3Endpoint,
        ["S3_ACCESS_KEY"] = TestEnvironment.S3AccessKey,
        ["S3_SECRET_KEY"] = TestEnvironment.S3SecretKey,
        ["S3_BUCKET_PRIVATE"] = "pao-net-test-private",
        ["S3_BUCKET_PUBLIC"] = "pao-net-test-public",
        ["JWT_SIGNING_KEY"] = TestEnvironment.Key,
        ["DATA_ENCRYPTION_KEY"] = TestEnvironment.Key,
        ["HTTP_ADDR"] = "127.0.0.1:0",
        ["METRICS_ADDR"] = "127.0.0.1:0",
    };
}
