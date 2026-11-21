using System.Globalization;
using PAO.EF.Notification;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Notification;

/// <summary>The Notification area's maps: rows to inbox items, items to views.</summary>
public sealed class NotificationMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<NotificationRecord, InboxItem>((r, _) => new InboxItem
        {
            Id = r.Id,
            Type = r.Type,
            Title = r.Title,
            Body = r.Body,
            BookingId = r.BookingId,
            Read = r.ReadAt is not null,
            CreatedAt = r.CreatedAt,
        })
        .Add<InboxItem, NotificationView>((i, _) => new NotificationView
        {
            Id = i.Id,
            Type = i.Type,
            Title = i.Title,
            Body = i.Body,
            BookingId = i.BookingId,
            Read = i.Read,
            CreatedAt = i.CreatedAt.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture),
        });
}
