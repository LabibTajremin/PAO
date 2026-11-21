using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Audit;
using PAO.Lib.Areas.Audit;

namespace PAO.Core.Areas.Audit.Repositories;

/// <summary>
/// Appends and reads `audit.entries`; there is deliberately no update or delete, and the
/// table's triggers reject them anyway. An entry for an already audited event is skipped.
/// </summary>
public interface IAuditRepository
{
    /// <summary>Appends `entry`, written from event `eventId` when given.</summary>
    Task Append(AuditEntry entry, Guid? eventId, CancellationToken cancellationToken);

    /// <summary>A page of entries, newest first.</summary>
    Task<IReadOnlyList<AuditEntry>> List(AuditFilter filter, AuditPage page, CancellationToken cancellationToken);
}

/// <summary>The <see cref="IAuditRepository"/> on the scope's <see cref="PaoDbContext"/>.</summary>
public sealed class AuditRepository(PaoDbContext db) : IAuditRepository
{
    /// <inheritdoc />
    public Task Append(AuditEntry entry, Guid? eventId, CancellationToken cancellationToken)
    {
        var at = entry.At.ToUniversalTime();
        var before = entry.Before?.ToJsonString();
        var after = entry.After?.ToJsonString();
        return db.Database.ExecuteSqlInterpolatedAsync(
            $"""
            INSERT INTO audit.entries (id, at, actor_id, actor_role, action, subject_type, subject_id, reason, before, after, event_id)
            VALUES ({entry.Id}, {at}, {entry.ActorId}, {entry.ActorRole}, {entry.Action}, {entry.SubjectType}, {entry.SubjectId},
                    {entry.Reason}, {before}::jsonb, {after}::jsonb, {eventId})
            ON CONFLICT (event_id) DO NOTHING
            """,
            cancellationToken);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<AuditEntry>> List(AuditFilter filter, AuditPage page, CancellationToken cancellationToken)
    {
        // Row comparison keeps Postgres' uuid order, which the (at, id) index serves.
        var query = page.AfterAt is { } afterAt && page.AfterId is { } afterId
            ? db.Set<Entry>().FromSqlInterpolated($"SELECT * FROM audit.entries WHERE (at, id) < ({afterAt.ToUniversalTime()}, {afterId})")
            : db.Set<Entry>().AsQueryable();
        query = filter.ActorId is { } actor ? query.Where(e => e.ActorId == actor) : query;
        query = filter.Action is { } action ? query.Where(e => e.Action == action) : query;
        query = filter.SubjectType is { } type ? query.Where(e => e.SubjectType == type) : query;
        query = filter.SubjectId is { } subject ? query.Where(e => e.SubjectId == subject) : query;
        query = filter.From is { } from ? query.Where(e => e.At >= from.ToUniversalTime()) : query;
        query = filter.To is { } to ? query.Where(e => e.At <= to.ToUniversalTime()) : query;
        var rows = await query.OrderByDescending(e => e.At).ThenByDescending(e => e.Id).Take(page.Limit).ToListAsync(cancellationToken);
        return [.. rows.Select(ToEntry)];
    }

    private static AuditEntry ToEntry(Entry e) => new()
    {
        Id = e.Id,
        At = e.At,
        ActorId = e.ActorId,
        ActorRole = e.ActorRole,
        Action = e.Action,
        SubjectType = e.SubjectType,
        SubjectId = e.SubjectId,
        Reason = e.Reason,
        Before = e.Before is null ? null : JsonNode.Parse(e.Before)!.AsObject(),
        After = e.After is null ? null : JsonNode.Parse(e.After)!.AsObject(),
    };
}
