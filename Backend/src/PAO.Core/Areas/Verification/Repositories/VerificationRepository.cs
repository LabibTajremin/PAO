using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Verification;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Verification.Repositories;

/// <summary>A keyset position over (time, id); `Limit` includes the look-ahead row.</summary>
public sealed record Page(DateTimeOffset? At, Guid? Id, int Limit);

/// <summary>A submitted merchant with items waiting for a decision (A-03).</summary>
public sealed record QueueRow
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>When the enrolment was submitted.</summary>
    public DateTimeOffset SubmittedAt { get; init; }
    /// <summary>The services offered.</summary>
    public Guid[] ServiceIds { get; init; } = [];
    /// <summary>Items waiting, by type.</summary>
    public string[] PendingItems { get; init; } = [];
}

/// <summary>An approved item with an expiry date.</summary>
public sealed record ExpiringItem
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>The item.</summary>
    public string ItemType { get; init; } = string.Empty;
    /// <summary>When it expires.</summary>
    public DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>Reads across merchants: levels, the review queue, sessions, expiry and the NID block list.</summary>
public sealed class VerificationRepository(PaoDbContext db, IMapper mapper)
{
    /// <summary>The merchant's level; 0 when never seen.</summary>
    public async Task<int> Level(Guid id, CancellationToken cancellationToken) =>
        await db.Set<VerificationLevelRecord>().Where(l => l.ProviderId == id).Select(l => (int?)l.Level).FirstOrDefaultAsync(cancellationToken) ?? 0;

    /// <summary>Levels of many merchants with one query; unknown ones are absent.</summary>
    public async Task<IReadOnlyDictionary<Guid, int>> Levels(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken) =>
        await db.Set<VerificationLevelRecord>().Where(l => ids.Contains(l.ProviderId)).ToDictionaryAsync(l => l.ProviderId, l => l.Level, cancellationToken);

    /// <summary>Submitted merchants with an item awaiting review (A-09).</summary>
    public async Task<int> CountPendingReviews(CancellationToken cancellationToken) =>
        (await db.Database.SqlQuery<int>($"""
            SELECT count(DISTINCT l.provider_id)::int AS "Value" FROM verification.levels l
            JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
            WHERE l.submitted_at IS NOT NULL
            """).ToListAsync(cancellationToken))[0];

    /// <summary>Submitted merchants with pending items, oldest first, optionally narrowed by item and service.</summary>
    public Task<List<QueueRow>> Queue(string? itemType, Guid? serviceId, Page page, CancellationToken cancellationToken) =>
        db.Database.SqlQuery<QueueRow>($"""
            SELECT l.provider_id AS "ProviderId", l.submitted_at AS "SubmittedAt", l.service_ids AS "ServiceIds",
                array_agg(i.item_type ORDER BY i.item_type)::text[] AS "PendingItems"
            FROM verification.levels l
            JOIN verification.items i ON i.provider_id = l.provider_id AND i.status = 'pending'
            WHERE l.submitted_at IS NOT NULL
              AND ({serviceId}::uuid IS NULL OR {serviceId}::uuid = ANY(l.service_ids))
              AND ({page.At}::timestamptz IS NULL OR (l.submitted_at, l.provider_id) > ({page.At}::timestamptz, {page.Id}::uuid))
            GROUP BY l.provider_id, l.submitted_at, l.service_ids
            HAVING {itemType}::text IS NULL OR {itemType}::text = ANY(array_agg(i.item_type))
            ORDER BY l.submitted_at, l.provider_id LIMIT {page.Limit}
            """).ToListAsync(cancellationToken);

    /// <summary>Sessions, newest first, optionally narrowed by merchant and status.</summary>
    public async Task<IReadOnlyList<Level2SessionState>> Sessions(Guid? providerId, string? status, Page page, CancellationToken cancellationToken) =>
        mapper.MapAll<Level2SessionRecord, Level2SessionState>(await db.Set<Level2SessionRecord>().FromSql($"""
            SELECT * FROM verification.level2_sessions
            WHERE ({providerId}::uuid IS NULL OR provider_id = {providerId}::uuid)
              AND ({status}::text IS NULL OR status = {status}::text)
              AND ({page.At}::timestamptz IS NULL OR (created_at, id) < ({page.At}::timestamptz, {page.Id}::uuid))
            ORDER BY created_at DESC, id DESC LIMIT {page.Limit}
            """).AsNoTracking().ToListAsync(cancellationToken));

    /// <summary>One session; throws `verification.provider_not_found`.</summary>
    public async Task<Level2SessionState> Session(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<Level2SessionRecord>().AsNoTracking().FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new DomainException(VerificationReasons.NotFound);
        return mapper.Map<Level2SessionRecord, Level2SessionState>(row);
    }

    /// <summary>Merchants with approved items whose expiry is at or before `at`.</summary>
    public Task<List<Guid>> ExpiredBy(DateTimeOffset at, CancellationToken cancellationToken) =>
        db.Set<VerificationItemRecord>().Where(i => i.Status == ItemStatus.Approved && i.ExpiresAt <= at)
            .Select(i => i.ProviderId).Distinct().ToListAsync(cancellationToken);

    /// <summary>Approved items expiring in (`after`, `until`].</summary>
    public Task<List<ExpiringItem>> ExpiringBetween(DateTimeOffset after, DateTimeOffset until, CancellationToken cancellationToken) =>
        db.Set<VerificationItemRecord>()
            .Where(i => i.Status == ItemStatus.Approved && i.ExpiresAt > after && i.ExpiresAt <= until)
            .OrderBy(i => i.ExpiresAt)
            .Select(i => new ExpiringItem { ProviderId = i.ProviderId, ItemType = i.ItemType, ExpiresAt = i.ExpiresAt!.Value })
            .ToListAsync(cancellationToken);

    /// <summary>Records the reminders with one statement and returns those not sent before.</summary>
    public Task<List<ExpiringItem>> RecordReminders(IReadOnlyList<ExpiringItem> items, int daysBefore, DateTimeOffset now, CancellationToken cancellationToken)
    {
        var providers = items.Select(i => i.ProviderId).ToArray();
        var types = items.Select(i => i.ItemType).ToArray();
        var expiries = items.Select(i => i.ExpiresAt).ToArray();
        return db.Database.SqlQuery<ExpiringItem>($"""
            INSERT INTO verification.reminders_sent (provider_id, item_type, expires_at, days_before, sent_at)
            SELECT p, t, e, {daysBefore}, {now} FROM unnest({providers}, {types}, {expiries}) AS r(p, t, e)
            ON CONFLICT DO NOTHING
            RETURNING provider_id AS "ProviderId", item_type AS "ItemType", expires_at AS "ExpiresAt"
            """).ToListAsync(cancellationToken);
    }

    /// <summary>Whether the NID hash is on the block list.</summary>
    public Task<bool> NidBlocked(string hash, CancellationToken cancellationToken) =>
        db.Set<BlockedNidRecord>().AnyAsync(b => b.NidHash == hash, cancellationToken);

    /// <summary>Adds the merchant's NID hash, if any, to the block list (PRD §6.4).</summary>
    public Task BlockNid(Guid providerId, string reason, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO verification.blocked_nids (nid_hash, reason)
        SELECT nid_hash, {reason} FROM verification.nid_records WHERE provider_id = {providerId}
        ON CONFLICT DO NOTHING
        """, cancellationToken);

    /// <summary>Sets whether the merchant is blocked, creating the level row of one never seen.</summary>
    public Task SetBlocked(Guid providerId, bool blocked, DateTimeOffset now, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO verification.levels (provider_id, blocked, updated_at) VALUES ({providerId}, {blocked}, {now})
        ON CONFLICT (provider_id) DO UPDATE SET blocked = excluded.blocked, updated_at = excluded.updated_at
        """, cancellationToken);
}
