using System.Globalization;
using PAO.EF.Media;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Media;

/// <summary>The Media area's maps: rows to stored objects, objects to views and contract DTOs.</summary>
public sealed class MediaMappingProfile : IMappingProfile
{
    /// <summary>The ISO 8601 form the API uses for times (milliseconds, UTC).</summary>
    public static string Iso(DateTimeOffset at) => at.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);

    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<MediaObjectRecord, StoredObject>((r, _) => new StoredObject
        {
            Id = r.Id,
            OwnerId = r.OwnerId,
            Purpose = r.Purpose,
            ContentType = r.ContentType,
            SizeBytes = r.SizeBytes,
            Bucket = r.Bucket,
            Key = r.ObjectKey,
            Confirmed = r.Status == "confirmed",
            Attached = r.Attached,
            CreatedAt = r.CreatedAt,
        })
        .Add<StoredObject, MediaObjectView>((o, _) => new MediaObjectView
        {
            Id = o.Id,
            Purpose = o.Purpose,
            ContentType = o.ContentType,
            SizeBytes = o.SizeBytes,
            Status = "confirmed",
        })
        .Add<StoredObject, MediaObject>((o, _) => new MediaObject
        {
            Id = o.Id,
            OwnerId = o.OwnerId,
            Purpose = o.Purpose,
            ContentType = o.ContentType,
            SizeBytes = o.SizeBytes,
            Confirmed = o.Confirmed,
        })
        .Add<UploadTicket, UploadTicketView>((t, _) => new UploadTicketView
        {
            MediaId = t.MediaId,
            UploadUrl = t.Url,
            Headers = t.Headers,
            ExpiresAt = Iso(t.ExpiresAt),
        })
        .Add<ViewUrl, ViewUrlView>((v, _) => new ViewUrlView { Url = v.Url, ExpiresAt = Iso(v.ExpiresAt) });
}
