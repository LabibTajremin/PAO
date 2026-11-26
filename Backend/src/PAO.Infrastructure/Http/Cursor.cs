using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.WebUtilities;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Http.Errors;

namespace PAO.Infrastructure.Http;

/// <summary>
/// The last row of a page, ordered by (created_at, id) descending. `CreatedAt` keeps the
/// timestamp as text so Postgres' microseconds survive the round trip. The encoding is
/// the earlier format (`{"t","i"}` in base64url), so cursors issued before the cut-over still work.
/// </summary>
public sealed partial record Cursor(string CreatedAt, string Id)
{
    /// <summary>Page size when the client asks for none (04-decisions E7).</summary>
    public const int DefaultPageSize = 20;

    /// <summary>The largest page a client may ask for.</summary>
    public const int MaxPageSize = 100;

    private static readonly ApiError Invalid = ApiErrors.Validation("field", "cursor");

    /// <summary>The opaque cursor string for this position.</summary>
    public string Encode() => WebEncoders.Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new { t = CreatedAt, i = Id }));

    /// <summary>Parses a cursor; none or empty means the first page, a malformed one is a 422.</summary>
    public static Cursor? Decode(string? text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return null;
        }
        if (!Base64Url().IsMatch(text))
        {
            throw Invalid;
        }
        try
        {
            using var document = JsonDocument.Parse(WebEncoders.Base64UrlDecode(text));
            var root = document.RootElement;
            var t = root.ValueKind == JsonValueKind.Object && root.TryGetProperty("t", out var tv) && tv.ValueKind == JsonValueKind.String ? tv.GetString() : null;
            var i = root.ValueKind == JsonValueKind.Object && root.TryGetProperty("i", out var iv) && iv.ValueKind == JsonValueKind.String ? iv.GetString() : null;
            if (t is null || !DateTimeOffset.TryParse(t, System.Globalization.CultureInfo.InvariantCulture, out _)
                || !UuidText.IsValid(i) || i == UuidText.Nil)
            {
                throw Invalid;
            }
            return new Cursor(t, i!);
        }
        catch (Exception e) when (e is JsonException or FormatException)
        {
            throw Invalid;
        }
    }

    /// <summary>The requested page size clamped to [1, <see cref="MaxPageSize"/>].</summary>
    public static int PageSize(int? limit) => limit is null or < 1 ? DefaultPageSize : Math.Min(limit.Value, MaxPageSize);

    [GeneratedRegex("^[A-Za-z0-9_-]+$")]
    private static partial Regex Base64Url();
}
