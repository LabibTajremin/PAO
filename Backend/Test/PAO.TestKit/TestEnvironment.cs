namespace PAO.TestKit;

/// <summary>
/// The services tests run against (ADR-0008): PAO_TEST_* variables, defaulting to the local
/// docker compose stack. The same names the NestJS test kit read.
/// </summary>
public static class TestEnvironment
{
    private static readonly Dictionary<string, string> Defaults = new()
    {
        ["PAO_TEST_DATABASE_URL"] = "postgres://pao:pao@localhost:5432/pao?sslmode=disable",
        ["PAO_TEST_REDIS_URL"] = "redis://localhost:6379/15",
        ["PAO_TEST_S3_ENDPOINT"] = "http://localhost:9000",
        ["PAO_TEST_S3_ACCESS_KEY"] = "pao-local",
        ["PAO_TEST_S3_SECRET_KEY"] = "change-me-local-only",
    };

    /// <summary>Reads `name`, falling back to the compose default.</summary>
    public static string Get(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrEmpty(value) ? Defaults[name] : value;
    }

    /// <summary>The admin database URL.</summary>
    public static string DatabaseUrl => Get("PAO_TEST_DATABASE_URL");

    /// <summary>The Redis URL; tests isolate themselves by key prefix.</summary>
    public static string RedisUrl => Get("PAO_TEST_REDIS_URL");

    /// <summary>The S3 endpoint.</summary>
    public static string S3Endpoint => Get("PAO_TEST_S3_ENDPOINT");

    /// <summary>The S3 access key.</summary>
    public static string S3AccessKey => Get("PAO_TEST_S3_ACCESS_KEY");

    /// <summary>The S3 secret key.</summary>
    public static string S3SecretKey => Get("PAO_TEST_S3_SECRET_KEY");

    /// <summary>A base64 32-byte key used for JWT seeds and data keys in tests.</summary>
    public const string Key = "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";

    /// <summary>Returns `url` pointing at database `name`.</summary>
    public static string WithDatabase(string url, string name)
    {
        var builder = new UriBuilder(url) { Path = "/" + name };
        return builder.Uri.ToString();
    }

    /// <summary>A unique name with `prefix`, for databases, buckets and Redis environments.</summary>
    public static string Unique(string prefix) => prefix + Guid.NewGuid().ToString("N")[..12];
}
