using System.Collections;

namespace PAO.Infrastructure.Configuration;

/// <summary>
/// Maps the deployment's environment variables (`.env.example`, infra/docker-compose.yml):
/// each maps onto a configuration key, which the config files only default. An empty
/// variable counts as unset.
/// </summary>
public static class EnvironmentVariables
{
    /// <summary>Environment variable → configuration key.</summary>
    public static readonly IReadOnlyDictionary<string, string> Keys = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["APP_ENV"] = "App:Environment",
        ["ADMIN_CORS_ORIGIN"] = "App:AdminCorsOrigin",
        ["DATA_ENCRYPTION_KEY"] = "App:DataEncryptionKey",
        ["SEED_ADMIN_PASSWORD"] = "App:SeedAdminPassword",
        ["LOG_LEVEL"] = "Logging:Level",
        ["HTTP_ADDR"] = "Http:Address",
        ["METRICS_ADDR"] = "Http:MetricsAddress",
        ["DATABASE_URL"] = "Database:Url",
        ["REDIS_URL"] = "Redis:Url",
        ["S3_ENDPOINT"] = "Storage:Endpoint",
        ["S3_PUBLIC_ENDPOINT"] = "Storage:PublicEndpoint",
        ["S3_REGION"] = "Storage:Region",
        ["S3_ACCESS_KEY"] = "Storage:AccessKey",
        ["S3_SECRET_KEY"] = "Storage:SecretKey",
        ["S3_BUCKET_PRIVATE"] = "Storage:BucketPrivate",
        ["S3_BUCKET_PUBLIC"] = "Storage:BucketPublic",
        ["JWT_SIGNING_KEY"] = "Jwt:SigningKey",
        ["JWT_KEY_ID"] = "Jwt:KeyId",
        ["JWT_PREVIOUS_PUBLIC_KEYS"] = "Jwt:PreviousPublicKeys",
        ["SMS_ADAPTER"] = "Sms:Adapter",
        ["SSLWIRELESS_API_TOKEN"] = "Sms:SslWirelessApiToken",
        ["SSLWIRELESS_SID"] = "Sms:SslWirelessSid",
        ["PUSH_ADAPTER"] = "Push:Adapter",
        ["FCM_CREDENTIALS_FILE"] = "Push:FcmCredentialsFile",
    };

    /// <summary>Returns the configuration values the set variables of `environment` define.</summary>
    public static Dictionary<string, string?> Map(IDictionary environment)
    {
        var values = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
        foreach (var (variable, key) in Keys)
        {
            if (environment[variable] is string { Length: > 0 } value)
            {
                values[key] = value;
            }
        }
        return values;
    }
}
