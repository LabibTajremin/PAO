using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace PAO.Infrastructure.Push;

/// <summary>Sends through the Firebase Cloud Messaging HTTP v1 API.</summary>
public sealed class FcmPushSender(HttpClient http, string endpoint, GoogleAccessTokens tokens) : IPushSender
{
    /// <summary>The send URL of `projectId`.</summary>
    public static string EndpointFor(string projectId) => $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

    /// <summary>
    /// FCM answers 404 (UNREGISTERED) or 400 for tokens that will never work again; those
    /// become <see cref="InvalidPushTokenException"/>.
    /// </summary>
    public async Task Push(string token, PushMessage message, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint) { Content = JsonContent.Create(Payload(token, message)) };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.AccessToken(cancellationToken));
        using var response = await http.SendAsync(request, cancellationToken);
        if (response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.BadRequest)
        {
            throw new InvalidPushTokenException();
        }
        if ((int)response.StatusCode >= 300)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException($"fcm: {(int)response.StatusCode} {body[..Math.Min(body.Length, 512)]}");
        }
    }

    /// <summary>
    /// The FCM v1 message. A heads-up banner needs a high-importance channel and high priority on
    /// Android, and apns-priority 10 with an alert push type on iOS; without them the
    /// notification only lands silently in the tray.
    /// </summary>
    public static object Payload(string token, PushMessage message)
    {
        var channel = PushChannels.For(message.Data.GetValueOrDefault("type"));
        return new
        {
            message = new
            {
                token,
                notification = new { title = message.Title, body = message.Body },
                data = message.Data,
                android = new
                {
                    priority = "high",
                    notification = new { channel_id = channel, notification_priority = "PRIORITY_HIGH", default_sound = true },
                },
                apns = new
                {
                    headers = new Dictionary<string, string> { ["apns-priority"] = "10", ["apns-push-type"] = "alert" },
                    payload = new Dictionary<string, object>
                    {
                        ["aps"] = new Dictionary<string, string> { ["sound"] = "default", ["interruption-level"] = PushChannels.InterruptionLevel(channel) },
                    },
                },
            },
        };
    }
}
