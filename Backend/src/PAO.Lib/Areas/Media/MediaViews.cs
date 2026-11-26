namespace PAO.Lib.Areas.Media;

/// <summary>The body of createCustomerUpload and createProviderUpload.</summary>
public sealed record UploadInput
{
    /// <summary>The purpose.</summary>
    public required string Purpose { get; init; }
    /// <summary>The content type.</summary>
    public required string ContentType { get; init; }
    /// <summary>The size in bytes.</summary>
    public required long SizeBytes { get; init; }
}

/// <summary>The API shape of an upload ticket: PUT the file to `UploadUrl` with `Headers`, then confirm.</summary>
public sealed record UploadTicketView
{
    /// <summary>The media id.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>The presigned URL.</summary>
    public required string UploadUrl { get; init; }
    /// <summary>The headers the PUT must carry.</summary>
    public required IReadOnlyDictionary<string, string> Headers { get; init; }
    /// <summary>When the URL stops working (ISO 8601).</summary>
    public required string ExpiresAt { get; init; }
}

/// <summary>The API shape of a confirmed upload.</summary>
public sealed record MediaObjectView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The purpose.</summary>
    public required string Purpose { get; init; }
    /// <summary>The content type.</summary>
    public required string ContentType { get; init; }
    /// <summary>The size in bytes.</summary>
    public required long SizeBytes { get; init; }
    /// <summary>Always `confirmed` once the upload is confirmed.</summary>
    public required string Status { get; init; }
}

/// <summary>The API shape of a signed view URL.</summary>
public sealed record ViewUrlView
{
    /// <summary>The URL.</summary>
    public required string Url { get; init; }
    /// <summary>When it stops working (ISO 8601).</summary>
    public required string ExpiresAt { get; init; }
}

/// <summary>A stored file's record, as the area's services see it.</summary>
public sealed record StoredObject
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The owner.</summary>
    public required Guid OwnerId { get; init; }
    /// <summary>The purpose.</summary>
    public required string Purpose { get; init; }
    /// <summary>The declared content type.</summary>
    public required string ContentType { get; init; }
    /// <summary>The declared size.</summary>
    public required long SizeBytes { get; init; }
    /// <summary>The bucket.</summary>
    public required string Bucket { get; init; }
    /// <summary>The object key.</summary>
    public required string Key { get; init; }
    /// <summary>Whether the upload was confirmed.</summary>
    public required bool Confirmed { get; init; }
    /// <summary>Whether a record references it.</summary>
    public required bool Attached { get; init; }
    /// <summary>When the upload was requested.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Reasons the media use cases raise; `not_found` and `not_uploaded` are also contract reasons.</summary>
public static class MediaReasons
{
    /// <summary>The file type or size breaks the purpose's rule.</summary>
    public const string Invalid = "media.invalid";
    /// <summary>This app may not upload files of that purpose.</summary>
    public const string Forbidden = "media.forbidden";
}

/// <summary>Deletes uploads never attached within a day (job `media.purge_orphans`); returns how many went.</summary>
public sealed record PurgeOrphanMedia : Mediator.ICommand<int>;

/// <summary>Deletes a deleted account's own files; its documents wait for the retention purge.</summary>
public sealed record DeleteAccountMedia(Guid AccountId) : Mediator.ICommand<int>;
