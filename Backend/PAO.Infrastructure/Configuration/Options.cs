namespace PAO.Infrastructure.Configuration;

/// <summary>Deployment environment and app-wide settings (`Config/app.json`).</summary>
public sealed class AppOptions
{
    /// <summary>The `"App"` value.</summary>
    public const string Section = "App";

    /// <summary>dev | test | staging | prod; "test" mounts the e2e test hooks.</summary>
    public string Environment { get; set; } = AppEnvironments.Dev;
    /// <summary>The admin cors origin.</summary>
    public string AdminCorsOrigin { get; set; } = "http://localhost:5000";

    /// <summary>AES-256 key (base64) for encrypted fields; a secret, from DATA_ENCRYPTION_KEY.</summary>
    public string DataEncryptionKey { get; set; } = string.Empty;
    /// <summary>The seed admin password.</summary>
    public string SeedAdminPassword { get; set; } = string.Empty;
}

/// <summary>The values of APP_ENV.</summary>
public static class AppEnvironments
{
    /// <summary>The `"dev"` value.</summary>
    public const string Dev = "dev";
    /// <summary>The `"test"` value.</summary>
    public const string Test = "test";
    /// <summary>The `"staging"` value.</summary>
    public const string Staging = "staging";
    /// <summary>The `"prod"` value.</summary>
    public const string Prod = "prod";
}

/// <summary>PostgreSQL (`Config/database.json`).</summary>
public sealed class DatabaseOptions
{
    /// <summary>The `"Database"` value.</summary>
    public const string Section = "Database";
    /// <summary>The URL.</summary>
    public string Url { get; set; } = string.Empty;
}

/// <summary>Redis (`Config/redis.json`).</summary>
public sealed class RedisOptions
{
    /// <summary>The `"Redis"` value.</summary>
    public const string Section = "Redis";
    /// <summary>The URL.</summary>
    public string Url { get; set; } = string.Empty;
}

/// <summary>Access-token keys (`Config/jwt.json`); the keys themselves come from the environment.</summary>
public sealed class JwtOptions
{
    /// <summary>The `"Jwt"` value.</summary>
    public const string Section = "Jwt";
    /// <summary>The key id.</summary>
    public string KeyId { get; set; } = "k1";
    /// <summary>The signing key.</summary>
    public string SigningKey { get; set; } = string.Empty;

    /// <summary>Public keys still accepted during rotation: `kid:base64pub,kid2:base64pub`.</summary>
    public string PreviousPublicKeys { get; set; } = string.Empty;
    /// <summary>The access token TTL seconds.</summary>
    public int AccessTokenTtlSeconds { get; set; } = 900;
}

/// <summary>Log level and the folder of the date-named log directories (`Config/logging.json`).</summary>
public sealed class LoggingOptions
{
    /// <summary>The `"Logging"` value.</summary>
    public const string Section = "Logging";
    /// <summary>The level.</summary>
    public string Level { get; set; } = "info";
    /// <summary>The directory.</summary>
    public string Directory { get; set; } = "Logs";
    /// <summary>Whether write files.</summary>
    public bool WriteFiles { get; set; } = true;
}

/// <summary>Outgoing mail (`Config/smtp.json`); no feature sends mail yet.</summary>
public sealed class SmtpOptions
{
    /// <summary>The `"Smtp"` value.</summary>
    public const string Section = "Smtp";
    /// <summary>The host.</summary>
    public string Host { get; set; } = string.Empty;
    /// <summary>The port.</summary>
    public int Port { get; set; } = 587;
    /// <summary>Whether use tls.</summary>
    public bool UseTls { get; set; } = true;
    /// <summary>The from.</summary>
    public string From { get; set; } = string.Empty;
    /// <summary>The username.</summary>
    public string Username { get; set; } = string.Empty;
    /// <summary>The password.</summary>
    public string Password { get; set; } = string.Empty;
}

/// <summary>S3-compatible storage (`Config/storage.json`).</summary>
public sealed class StorageOptions
{
    /// <summary>The `"Storage"` value.</summary>
    public const string Section = "Storage";
    /// <summary>The endpoint.</summary>
    public string Endpoint { get; set; } = string.Empty;

    /// <summary>What devices reach; inside Docker it differs from <see cref="Endpoint"/>.</summary>
    public string PublicEndpoint { get; set; } = string.Empty;
    /// <summary>The region.</summary>
    public string Region { get; set; } = "us-east-1";
    /// <summary>The access key.</summary>
    public string AccessKey { get; set; } = string.Empty;
    /// <summary>The secret key.</summary>
    public string SecretKey { get; set; } = string.Empty;
    /// <summary>The bucket private.</summary>
    public string BucketPrivate { get; set; } = string.Empty;
    /// <summary>The bucket public.</summary>
    public string BucketPublic { get; set; } = string.Empty;
}

/// <summary>Text messages (`Config/sms.json`).</summary>
public sealed class SmsOptions
{
    /// <summary>The `"Sms"` value.</summary>
    public const string Section = "Sms";

    /// <summary>console | sslwireless.</summary>
    public string Adapter { get; set; } = "console";
    /// <summary>The ssl wireless endpoint.</summary>
    public string SslWirelessEndpoint { get; set; } = "https://smsplus.sslwireless.com/api/v3/send-sms";
    /// <summary>The ssl wireless api token.</summary>
    public string SslWirelessApiToken { get; set; } = string.Empty;
    /// <summary>The ssl wireless sid.</summary>
    public string SslWirelessSid { get; set; } = string.Empty;
    /// <summary>The timeout seconds.</summary>
    public int TimeoutSeconds { get; set; } = 10;
}

/// <summary>Push notifications (`Config/push.json`).</summary>
public sealed class PushOptions
{
    /// <summary>The `"Push"` value.</summary>
    public const string Section = "Push";

    /// <summary>log | fcm.</summary>
    public string Adapter { get; set; } = "log";
    /// <summary>The fcm credentials file.</summary>
    public string FcmCredentialsFile { get; set; } = string.Empty;
}

/// <summary>The worker's relay and jobs (`Config/jobs.json`).</summary>
public sealed class JobsOptions
{
    /// <summary>The `"Jobs"` value.</summary>
    public const string Section = "Jobs";
    /// <summary>The outbox relay interval milliseconds.</summary>
    public int OutboxRelayIntervalMs { get; set; } = 250;
    /// <summary>The outbox retention days.</summary>
    public int OutboxRetentionDays { get; set; } = 7;
}

/// <summary>Listen addresses, body limit and API rate limits (`Config/http.json`).</summary>
public sealed class HttpOptions
{
    /// <summary>The `"Http"` value.</summary>
    public const string Section = "Http";
    /// <summary>The address.</summary>
    public string Address { get; set; } = ":8080";

    /// <summary>The internal address of /metrics (never exposed publicly).</summary>
    public string MetricsAddress { get; set; } = ":9090";
    /// <summary>The max body bytes.</summary>
    public int MaxBodyBytes { get; set; } = 1 << 20;
    /// <summary>The rate limit per user.</summary>
    public int RateLimitPerUser { get; set; } = 120;
    /// <summary>The rate limit per ip.</summary>
    public int RateLimitPerIp { get; set; } = 60;
    /// <summary>The rate limit window seconds.</summary>
    public int RateLimitWindowSeconds { get; set; } = 60;
}
