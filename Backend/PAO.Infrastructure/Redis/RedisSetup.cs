using System.Globalization;
using StackExchange.Redis;

namespace PAO.Infrastructure.Redis;

/// <summary>Builds keys under `pao:{env}:` so environments can share one server (02-architecture §4).</summary>
public sealed class RedisKeys(string environment)
{
    private readonly string prefix = $"pao:{environment}:";

    /// <summary>Joins parts with ":" under the prefix, e.g. `Key("otp", phone)`.</summary>
    public string Key(params string[] parts) => prefix + string.Join(':', parts);
}

/// <summary>Turns REDIS_URL (`redis://` or `rediss://`, optional password and db) into client options.</summary>
public static class RedisUrl
{
    /// <summary>Parses `url`; throws <see cref="FormatException"/> for anything else.</summary>
    public static ConfigurationOptions Parse(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme is not ("redis" or "rediss"))
        {
            throw new FormatException("parse redis url: scheme must be redis:// or rediss://");
        }
        var options = new ConfigurationOptions
        {
            Ssl = uri.Scheme == "rediss",
            AbortOnConnectFail = true,
            ConnectRetry = 2,
        };
        options.EndPoints.Add(uri.Host, uri.IsDefaultPort ? 6379 : uri.Port);
        var path = uri.AbsolutePath.Trim('/');
        if (path.Length > 0)
        {
            options.DefaultDatabase = int.Parse(path, NumberStyles.None, CultureInfo.InvariantCulture);
        }
        var userInfo = Uri.UnescapeDataString(uri.UserInfo);
        var colon = userInfo.IndexOf(':', StringComparison.Ordinal);
        if (colon >= 0)
        {
            options.User = colon > 0 ? userInfo[..colon] : null;
            options.Password = userInfo[(colon + 1)..];
        }
        return options;
    }

    /// <summary>Connects to `url` and checks that the server answers.</summary>
    public static async Task<IConnectionMultiplexer> Connect(string url)
    {
        var connection = await ConnectionMultiplexer.ConnectAsync(Parse(url));
        await connection.GetDatabase().PingAsync();
        return connection;
    }
}
