using System.Collections.Concurrent;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Testing;

namespace PAO.Infrastructure.Sms;

/// <summary>Delivers a text message to a phone (E.164).</summary>
public interface ISmsSender
{
    /// <summary>Sends `message` to `phone`.</summary>
    Task Send(string phone, string message, CancellationToken cancellationToken);
}

/// <summary>Logs messages instead of sending them; codes appear in the API log (development).</summary>
public sealed class ConsoleSmsSender(ILogger<ConsoleSmsSender> logger) : ISmsSender
{
    /// <inheritdoc />
    public Task Send(string phone, string message, CancellationToken cancellationToken)
    {
        logger.LogInformation("sms (console adapter) {Phone} {Message}", phone, message);
        return Task.CompletedTask;
    }
}

/// <summary>
/// Keeps the newest message per phone in memory so end-to-end tests can read one-time
/// codes through `/__test/sms`; wired only when APP_ENV=test.
/// </summary>
public sealed class CapturedSmsSender : ISmsSender, ISmsCapture
{
    private readonly ConcurrentDictionary<string, string> latest = new(StringComparer.Ordinal);

    /// <inheritdoc />
    public Task Send(string phone, string message, CancellationToken cancellationToken)
    {
        latest[phone] = message;
        return Task.CompletedTask;
    }

    /// <inheritdoc />
    public string? Last(string phone) => latest.GetValueOrDefault(phone);
}

/// <summary>Sends through the SSL Wireless SMS Plus API (D10), the production gateway.</summary>
public sealed class SslWirelessSmsSender(HttpClient http, SmsOptions options, IIdGenerator ids) : ISmsSender
{
    /// <inheritdoc />
    public async Task Send(string phone, string message, CancellationToken cancellationToken)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(options.TimeoutSeconds));
        var body = new Dictionary<string, string>
        {
            ["api_token"] = options.SslWirelessApiToken,
            ["sid"] = options.SslWirelessSid,
            ["msisdn"] = phone.TrimStart('+'),
            ["sms"] = message,
            // The gateway's client message id is at most 20 characters.
            ["csms_id"] = ids.NewId().ToString("N")[..20],
        };
        using var response = await http.PostAsJsonAsync(options.SslWirelessEndpoint, body, timeout.Token);
        var status = await StatusCode(response, timeout.Token);
        if (status != 200)
        {
            throw new HttpRequestException($"sms gateway rejected the message (http {(int)response.StatusCode}, status {status})");
        }
    }

    private static async Task<int> StatusCode(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        try
        {
            return (await response.Content.ReadFromJsonAsync<GatewayAnswer>(cancellationToken))?.StatusCode ?? 0;
        }
        catch (JsonException)
        {
            return 0;
        }
    }

    private sealed class GatewayAnswer
    {
        [JsonPropertyName("status_code")]
        public int? StatusCode { get; set; }
    }
}
