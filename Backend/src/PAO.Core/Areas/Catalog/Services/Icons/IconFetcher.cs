using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// Downloads an icon link once (ADR-0039): HTTPS only, through <see cref="PublicAddresses"/>,
/// no redirects, 5 seconds, and never more than the type's size limit.
/// </summary>
public sealed class IconFetcher(HttpClient http)
{
    /// <summary>The name of the configured <see cref="HttpClient"/>.</summary>
    public const string ClientName = "catalog-icons";

    /// <summary>The time allowed for the whole download.</summary>
    public static readonly TimeSpan Timeout = TimeSpan.FromSeconds(5);

    /// <summary>The file and its type; throws `catalog.icon_link_failed`, `icon_unreadable` or `icon_too_large`.</summary>
    public async Task<(string ContentType, byte[] File)> Fetch(string url, CancellationToken cancellationToken)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme != Uri.UriSchemeHttps)
        {
            throw new DomainException(CatalogReasons.IconLinkFailed);
        }
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(Timeout);
        try
        {
            using var response = await http.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
            CatalogChanges.Check(response.IsSuccessStatusCode, CatalogReasons.IconLinkFailed);
            var type = response.Content.Headers.ContentType?.MediaType ?? string.Empty;
            CatalogChanges.Check(IconTypes.Extension(type) is not null, CatalogReasons.IconUnreadable);
            return (type, await ReadLimited(response.Content, IconTypes.MaxBytes(type), timeout.Token));
        }
        catch (Exception error) when (error is HttpRequestException || (error is OperationCanceledException && !cancellationToken.IsCancellationRequested))
        {
            throw new DomainException(CatalogReasons.IconLinkFailed, error);
        }
    }

    private static async Task<byte[]> ReadLimited(HttpContent content, int limit, CancellationToken cancellationToken)
    {
        CatalogChanges.Check(content.Headers.ContentLength is not > 0 || content.Headers.ContentLength <= limit, CatalogReasons.IconTooLarge);
        await using var stream = await content.ReadAsStreamAsync(cancellationToken);
        var buffer = new MemoryStream();
        var chunk = new byte[16 * 1024];
        int read;
        while ((read = await stream.ReadAsync(chunk, cancellationToken)) > 0)
        {
            buffer.Write(chunk, 0, read);
            CatalogChanges.Check(buffer.Length <= limit, CatalogReasons.IconTooLarge);
        }
        return buffer.ToArray();
    }
}
