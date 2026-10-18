using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Notification;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Notification.Repositories;

/// <summary>Stores the inbox and device tokens (`notification` schema).</summary>
public sealed class NotificationRepository(PaoDbContext db, IMapper mapper)
{
    /// <summary>Stores a notification; false when its (recipient, dedupe key) was seen before.</summary>
    public async Task<bool> Add(NotificationRecord n, CancellationToken cancellationToken) =>
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO notification.notifications (id, recipient_id, app, type, title, body, booking_id, dedupe_key, created_at)
            VALUES ({n.Id}, {n.RecipientId}, {n.App}, {n.Type}, {n.Title}, {n.Body}, {n.BookingId}, {n.DedupeKey}, {n.CreatedAt})
            ON CONFLICT (recipient_id, dedupe_key) DO NOTHING
            """, cancellationToken) == 1;

    /// <summary>A recipient's notifications in one app, newest first, after the keyset position `before`.</summary>
    public async Task<IReadOnlyList<InboxItem>> List(Guid recipient, string app, (DateTimeOffset At, Guid Id)? before, int limit, CancellationToken cancellationToken)
    {
        var rows = before is { } b
            ? db.Set<NotificationRecord>().FromSql($"""
                SELECT * FROM notification.notifications
                WHERE recipient_id = {recipient} AND app = {app} AND (created_at, id) < ({b.At}, {b.Id})
                """)
            : db.Set<NotificationRecord>().Where(n => n.RecipientId == recipient && n.App == app);
        var page = await rows.OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id).Take(limit).ToListAsync(cancellationToken);
        return mapper.MapAll<NotificationRecord, InboxItem>(page);
    }

    /// <summary>How many are unread.</summary>
    public Task<int> Unread(Guid recipient, string app, CancellationToken cancellationToken) =>
        db.Set<NotificationRecord>().CountAsync(n => n.RecipientId == recipient && n.App == app && n.ReadAt == null, cancellationToken);

    /// <summary>Marks one notification read (keeping the first read time); `notification.not_found` when it is not theirs.</summary>
    public async Task MarkRead(Guid recipient, string app, Guid id, DateTimeOffset at, CancellationToken cancellationToken)
    {
        var changed = await db.Set<NotificationRecord>().Where(n => n.Id == id && n.RecipientId == recipient && n.App == app)
            .ExecuteUpdateAsync(u => u.SetProperty(n => n.ReadAt, n => n.ReadAt ?? at), cancellationToken);
        if (changed == 0)
        {
            throw new DomainException(NotificationReasons.NotFound);
        }
    }

    /// <summary>Marks every unread notification of the app read.</summary>
    public Task MarkAllRead(Guid recipient, string app, DateTimeOffset at, CancellationToken cancellationToken) =>
        db.Set<NotificationRecord>().Where(n => n.RecipientId == recipient && n.App == app && n.ReadAt == null)
            .ExecuteUpdateAsync(u => u.SetProperty(n => n.ReadAt, at), cancellationToken);

    /// <summary>Saves a token; it moves to whoever registered it last.</summary>
    public Task SaveDevice(DeviceTokenRecord d, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO notification.device_tokens (token, account_id, app, platform, updated_at)
        VALUES ({d.Token}, {d.AccountId}, {d.App}, {d.Platform}, {d.UpdatedAt})
        ON CONFLICT (token) DO UPDATE SET account_id = excluded.account_id, app = excluded.app, platform = excluded.platform,
            updated_at = excluded.updated_at
        """, cancellationToken);

    /// <summary>The newest ten device tokens of an account in an app.</summary>
    public async Task<IReadOnlyList<string>> Tokens(Guid account, string app, CancellationToken cancellationToken) =>
        await db.Set<DeviceTokenRecord>().Where(d => d.AccountId == account && d.App == app)
            .OrderByDescending(d => d.UpdatedAt).Take(10).Select(d => d.Token).ToListAsync(cancellationToken);

    /// <summary>Forgets a token that will never work again.</summary>
    public Task DropToken(string token, CancellationToken cancellationToken) =>
        db.Set<DeviceTokenRecord>().Where(d => d.Token == token).ExecuteDeleteAsync(cancellationToken);

    /// <summary>Erases an account's inbox and devices (PRD §11).</summary>
    public async Task Forget(Guid account, CancellationToken cancellationToken)
    {
        await db.Set<NotificationRecord>().Where(n => n.RecipientId == account).ExecuteDeleteAsync(cancellationToken);
        await db.Set<DeviceTokenRecord>().Where(d => d.AccountId == account).ExecuteDeleteAsync(cancellationToken);
    }
}
