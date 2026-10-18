using System.Globalization;
using PAO.Core.Areas.Notification.Repositories;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Notification.Features.Inbox.Queries;

/// <summary>One page of an app's inbox, newest first, with the unread count (C-13, P-12).</summary>
public sealed record ListNotifications(Guid Recipient, string App, string? Cursor, int? Limit) : IQuery<NotificationListView>;

/// <summary>Answers <see cref="ListNotifications"/> with a look-ahead row to know whether a next page exists.</summary>
public sealed class ListNotificationsHandler(NotificationRepository repository, IMapper mapper) : IRequestHandler<ListNotifications, NotificationListView>
{
    /// <inheritdoc />
    public async Task<NotificationListView> Handle(ListNotifications request, CancellationToken cancellationToken)
    {
        var cursor = Cursor.Decode(request.Cursor);
        var size = Cursor.PageSize(request.Limit);
        (DateTimeOffset, Guid)? before = cursor is null
            ? null
            : (DateTimeOffset.Parse(cursor.CreatedAt, CultureInfo.InvariantCulture), Guid.Parse(cursor.Id));
        var rows = await repository.List(request.Recipient, request.App, before, size + 1, cancellationToken);
        var items = rows.Take(size).ToList();
        var next = rows.Count > size ? new Cursor(items[^1].CreatedAt.ToString("O", CultureInfo.InvariantCulture), items[^1].Id.ToString()).Encode() : null;
        return new NotificationListView
        {
            Items = mapper.MapAll<InboxItem, NotificationView>(items),
            UnreadCount = await repository.Unread(request.Recipient, request.App, cancellationToken),
            NextCursor = next,
        };
    }
}
