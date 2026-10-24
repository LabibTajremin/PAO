using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Push;

/// <summary>A Google service account key (the JSON in FCM_CREDENTIALS_FILE).</summary>
public sealed record ServiceAccount(string ProjectId, string ClientEmail, string PrivateKeyPem, string TokenUri)
{
    /// <summary>Reads the key file's JSON; throws when a required field is missing.</summary>
    public static ServiceAccount Parse(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        string? Field(string name) =>
            root.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
        var project = Field("project_id");
        var email = Field("client_email");
        var key = Field("private_key");
        if (project is null || email is null || key is null)
        {
            throw new FormatException("fcm credentials: project_id, client_email and private_key are required");
        }
        return new ServiceAccount(project, email, key, Field("token_uri") ?? "https://oauth2.googleapis.com/token");
    }
}

/// <summary>
/// OAuth access tokens for the FCM scope from a service-account key (RFC 7523 JWT bearer
/// grant signed with RS256), cached until a minute before they expire.
/// </summary>
public sealed class GoogleAccessTokens(HttpClient http, ServiceAccount account, IClock clock)
{
    private const string Scope = "https://www.googleapis.com/auth/firebase.messaging";
    private readonly SemaphoreSlim gate = new(1, 1);
    private string? token;
    private DateTimeOffset expiresAt;

    /// <summary>A valid bearer token, fetching a new one when needed.</summary>
    public async Task<string> AccessToken(CancellationToken cancellationToken)
    {
        await gate.WaitAsync(cancellationToken);
        try
        {
            if (token is null || clock.Now >= expiresAt)
            {
                await Refresh(cancellationToken);
            }
            return token!;
        }
        finally
        {
            gate.Release();
        }
    }

    private async Task Refresh(CancellationToken cancellationToken)
    {
        var form = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer",
            ["assertion"] = Assertion(clock.Now),
        });
        using var response = await http.PostAsync(account.TokenUri, form, cancellationToken);
        var text = await response.Content.ReadAsStringAsync(cancellationToken);
        using var document = JsonDocument.Parse(response.IsSuccessStatusCode ? text : "{}");
        if (!document.RootElement.TryGetProperty("access_token", out var accessToken))
        {
            throw new HttpRequestException($"fcm: no access token ({(int)response.StatusCode})");
        }
        var lifetime = document.RootElement.TryGetProperty("expires_in", out var seconds) ? seconds.GetInt32() : 3600;
        token = accessToken.GetString();
        expiresAt = clock.Now + TimeSpan.FromSeconds(lifetime - 60);
    }

    private string Assertion(DateTimeOffset now)
    {
        var header = Encode(new { alg = "RS256", typ = "JWT" });
        var claims = Encode(new
        {
            iss = account.ClientEmail,
            scope = Scope,
            aud = account.TokenUri,
            iat = now.ToUnixTimeSeconds(),
            exp = now.ToUnixTimeSeconds() + 3600,
        });
        using var rsa = RSA.Create();
        rsa.ImportFromPem(account.PrivateKeyPem);
        var signature = rsa.SignData(Encoding.ASCII.GetBytes($"{header}.{claims}"), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        return $"{header}.{claims}.{WebEncoders.Base64UrlEncode(signature)}";
    }

    private static string Encode(object value) => WebEncoders.Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(value));
}
