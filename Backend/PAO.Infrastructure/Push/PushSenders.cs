using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Testing;

namespace PAO.Infrastructure.Push;

/// <summary>A push notification.</summary>
public sealed record PushMessage(string Title, string Body, IReadOnlyDictionary<string, string> Data);

/// <summary>Thrown for a device token that will never work again; the caller forgets it.</summary>
public sealed class InvalidPushTokenException() : Exception("push token invalid");

/// <summary>Delivers a push to one device token.</summary>
public interface IPushSender
{
    /// <summary>Sends `message` to `token`.</summary>
    Task Push(string token, PushMessage message, CancellationToken cancellationToken);
}

/// <summary>
/// Logs pushes and keeps the latest ones for development and tests (`/__test/pushes`).
/// Tokens starting with "invalid-" are rejected as dead and "broken-" ones fail, so token
/// clean-up and failure logging can be exercised without FCM.
/// </summary>
public sealed class CapturePushSender(ILogger<CapturePushSender> logger) : IPushSender, IPushCapture
{
    private const int Keep = 1000;
    private readonly Lock gate = new();
    private readonly List<(string Token, CapturedPush Push)> sent = [];

    /// <inheritdoc />
    public Task Push(string token, PushMessage message, CancellationToken cancellationToken)
    {
        if (token.StartsWith("invalid-", StringComparison.Ordinal))
        {
            return Task.FromException(new InvalidPushTokenException());
        }
        if (token.StartsWith("broken-", StringComparison.Ordinal))
        {
            return Task.FromException(new HttpRequestException("push service unavailable"));
        }
        logger.LogInformation("push {Title} {Type}", message.Title, message.Data.GetValueOrDefault("type"));
        lock (gate)
        {
            sent.Add((token, new CapturedPush(message.Title, message.Body, new Dictionary<string, string>(message.Data))));
            if (sent.Count > Keep)
            {
                sent.RemoveRange(0, sent.Count - Keep);
            }
        }
        return Task.CompletedTask;
    }

    /// <inheritdoc />
    public IReadOnlyList<CapturedPush> SentTo(string token)
    {
        lock (gate)
        {
            return [.. sent.Where(s => s.Token == token).Select(s => s.Push)];
        }
    }
}
