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
        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
        {
            Content = JsonContent.Create(new
            {
                message = new
                {
                    token,
                    notification = new { title = message.Title, body = message.Body },
                    data = message.Data,
                    android = new { priority = "high" },
                },
            }),
        };
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
}
