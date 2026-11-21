using System.Text;

namespace PAO.Infrastructure.Configuration;

/// <summary>
/// Where the FCM service account comes from (ADR-0036): FCM_CREDENTIALS_FILE when set,
/// otherwise FCM_CREDENTIALS_JSON, raw or base64, for hosts that only offer variables.
/// </summary>
public static class FcmCredentials
{
    /// <summary>The service-account JSON text of `options`.</summary>
    public static string Read(PushOptions options)
    {
        if (options.FcmCredentialsFile.Length > 0)
        {
            return File.ReadAllText(options.FcmCredentialsFile);
        }
        var inline = options.FcmCredentialsJson.Trim();
        // A JSON object starts with "{", which base64 never does.
        return inline.StartsWith('{') ? inline : Encoding.UTF8.GetString(Convert.FromBase64String(inline));
    }
}
