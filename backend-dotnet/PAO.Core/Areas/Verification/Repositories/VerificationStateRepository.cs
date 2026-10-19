using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Verification;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Events;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Verification.Repositories;

/// <summary>States loaded under their row locks, with the tracked rows a save rewrites.</summary>
public sealed class LockedStates
{
    /// <summary>The states, in id order.</summary>
    public required IReadOnlyList<VerificationState> States { get; init; }

    internal Dictionary<Guid, VerificationLevelRecord> Levels { get; init; } = [];

    internal Dictionary<(Guid, string), VerificationItemRecord> Items { get; init; } = [];

    internal Dictionary<Guid, Level2SessionRecord> Sessions { get; init; } = [];

    internal IReadOnlyList<VerificationDocumentRecord> Documents { get; init; } = [];

    internal Dictionary<Guid, NidRecord> Nids { get; init; } = [];
}

/// <summary>
/// Loads and saves whole merchant states. Each table is read once for any number of
/// merchants, and a save is one `SaveChanges` plus one outbox insert, so the expiry sweep
/// stays a handful of statements however many merchants it touches.
/// </summary>
public sealed class VerificationStateRepository(PaoDbContext db, IMapper mapper, IClock clock, IIdGenerator ids)
{
    /// <summary>The merchant's state for reading; a merchant never seen has an empty one.</summary>
    public async Task<VerificationState> Load(Guid id, CancellationToken cancellationToken)
    {
        var level = await db.Set<VerificationLevelRecord>().AsNoTracking().FirstOrDefaultAsync(l => l.ProviderId == id, cancellationToken);
        if (level is null)
        {
            return new VerificationState(id);
        }
        var locked = await Read([level], false, cancellationToken);
        return locked.States[0];
    }

    /// <summary>
    /// Locks the merchants' level rows (`FOR UPDATE`, creating missing ones) for the rest of
    /// the transaction, so concurrent decisions never compute a level from stale items.
    /// </summary>
    public async Task<LockedStates> LoadForUpdate(IReadOnlyCollection<Guid> providerIds, CancellationToken cancellationToken)
    {
        var keys = providerIds.Distinct().Order().ToArray();
        await db.Database.ExecuteSqlAsync(
            $"INSERT INTO verification.levels (provider_id) SELECT unnest({keys}) ON CONFLICT DO NOTHING", cancellationToken);
        var levels = await db.Set<VerificationLevelRecord>()
            .FromSql($"SELECT * FROM verification.levels WHERE provider_id = ANY({keys}) ORDER BY provider_id FOR UPDATE")
            .AsTracking().ToListAsync(cancellationToken);
        return await Read(levels, true, cancellationToken);
    }

    /// <summary>Writes the states and, in the same transaction, their events to `verification.outbox`.</summary>
    public async Task Save(LockedStates locked, IReadOnlyList<(Guid ProviderId, IDomainEvent Event)> events, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        foreach (var st in locked.States)
        {
            SaveLevel(locked.Levels[st.ProviderId], st, now);
            SaveItems(locked, st);
            SaveSessions(locked, st);
            SaveDocuments(locked, st);
            SaveNid(locked, st, now);
        }
        await db.SaveChangesAsync(cancellationToken);
        await WriteEvents(events, cancellationToken);
    }

    /// <summary>Appends events to `verification.outbox` with one statement.</summary>
    public async Task WriteEvents(IReadOnlyList<(Guid ProviderId, IDomainEvent Event)> events, CancellationToken cancellationToken)
    {
        if (events.Count == 0)
        {
            return;
        }
        var now = clock.Now;
        var eventIds = events.Select(_ => ids.NewId()).ToArray();
        var aggregates = events.Select(e => e.ProviderId.ToString()).ToArray();
        var names = events.Select(e => e.Event.Name).ToArray();
        var payloads = events.Select(e => JsonSerializer.Serialize(e.Event, e.Event.GetType(), PAO.Infrastructure.Outbox.OutboxWriter.Json)).ToArray();
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO verification.outbox (id, aggregate_id, event_name, payload, created_at, next_attempt_at)
            SELECT i, a, n, p::jsonb, {now}, {now} FROM unnest({eventIds}, {aggregates}, {names}, {payloads}) AS e(i, a, n, p)
            """, cancellationToken);
    }

    private async Task<LockedStates> Read(List<VerificationLevelRecord> levels, bool track, CancellationToken cancellationToken)
    {
        var keys = levels.Select(l => l.ProviderId).ToArray();
        IQueryable<T> Rows<T>()
            where T : class => track ? db.Set<T>().AsTracking() : db.Set<T>().AsNoTracking();
        var items = await Rows<VerificationItemRecord>().Where(i => keys.Contains(i.ProviderId)).ToListAsync(cancellationToken);
        var sessions = await Rows<Level2SessionRecord>().Where(s => keys.Contains(s.ProviderId))
            .OrderBy(s => s.CreatedAt).ThenBy(s => s.Id).ToListAsync(cancellationToken);
        var documents = await Rows<VerificationDocumentRecord>().Where(d => keys.Contains(d.ProviderId) && d.Current)
            .OrderBy(d => d.CreatedAt).ThenBy(d => d.Id).ToListAsync(cancellationToken);
        var nids = await Rows<NidRecord>().Where(n => keys.Contains(n.ProviderId)).ToDictionaryAsync(n => n.ProviderId, cancellationToken);
        var itemsBy = BatchLoader.GroupBy(items, i => i.ProviderId);
        var sessionsBy = BatchLoader.GroupBy(sessions, s => s.ProviderId);
        var documentsBy = BatchLoader.GroupBy(documents, d => d.ProviderId);
        var states = levels.Select(l => Build(l, itemsBy.GetValueOrDefault(l.ProviderId, []), sessionsBy.GetValueOrDefault(l.ProviderId, []),
            documentsBy.GetValueOrDefault(l.ProviderId, []), nids.GetValueOrDefault(l.ProviderId))).ToList();
        return new LockedStates
        {
            States = states,
            Levels = levels.ToDictionary(l => l.ProviderId),
            Items = items.ToDictionary(i => (i.ProviderId, i.ItemType)),
            Sessions = sessions.ToDictionary(s => s.Id),
            Documents = documents,
            Nids = nids,
        };
    }

    private VerificationState Build(
        VerificationLevelRecord level, IReadOnlyList<VerificationItemRecord> items, IReadOnlyList<Level2SessionRecord> sessions,
        IReadOnlyList<VerificationDocumentRecord> documents, NidRecord? nid)
    {
        var st = new VerificationState(level.ProviderId)
        {
            Level = level.Level,
            Level2PassedAt = level.Level2PassedAt,
            Blocked = level.Blocked,
            ServiceIds = level.ServiceIds,
            SubmittedAt = level.SubmittedAt,
            Sessions = [.. mapper.MapAll<Level2SessionRecord, Level2SessionState>(sessions)],
            NidCiphertext = nid?.NidCiphertext,
            NidHash = nid?.NidHash,
        };
        foreach (var item in mapper.MapAll<VerificationItemRecord, ItemState>(items))
        {
            st.Items[item.Type] = item;
        }
        st.Documents.AddRange(mapper.MapAll<VerificationDocumentRecord, VerificationDocument>(documents));
        return st;
    }

    private static void SaveLevel(VerificationLevelRecord row, VerificationState st, DateTimeOffset now)
    {
        row.Level = st.Level;
        row.Level2PassedAt = st.Level2PassedAt;
        row.Blocked = st.Blocked;
        row.ServiceIds = [.. st.ServiceIds];
        row.SubmittedAt = st.SubmittedAt;
        row.UpdatedAt = now;
    }

    private void SaveItems(LockedStates locked, VerificationState st)
    {
        foreach (var (type, it) in st.Items)
        {
            if (!locked.Items.TryGetValue((st.ProviderId, type), out var row))
            {
                row = new VerificationItemRecord { ProviderId = st.ProviderId, ItemType = type, Status = it.Status, RejectionReason = string.Empty, Fields = "{}" };
                db.Add(row);
                locked.Items[(st.ProviderId, type)] = row;
            }
            row.Status = it.Status;
            row.RejectionReason = it.Reason;
            row.Fields = JsonSerializer.Serialize(it.Fields, VerificationMappingProfile.Json);
            row.SubmittedAt = it.SubmittedAt;
            row.DecidedAt = it.DecidedAt;
            row.DecidedBy = it.DecidedBy;
            row.ExpiresAt = it.ExpiresAt;
        }
    }

    private void SaveSessions(LockedStates locked, VerificationState st)
    {
        foreach (var s in st.Sessions)
        {
            if (!locked.Sessions.TryGetValue(s.Id, out var row))
            {
                row = new Level2SessionRecord
                {
                    Id = s.Id,
                    ProviderId = s.ProviderId,
                    ServiceId = s.ServiceId,
                    ScheduledAt = s.ScheduledAt,
                    Location = s.Location,
                    Status = s.Status,
                    Checklist = "[]",
                    Notes = string.Empty,
                    CreatedAt = s.CreatedAt,
                };
                db.Add(row);
                locked.Sessions[s.Id] = row;
            }
            row.Status = s.Status;
            row.Result = s.Result.Length == 0 ? null : s.Result;
            row.Checklist = JsonSerializer.Serialize(s.Checklist, VerificationMappingProfile.Json);
            row.Notes = s.Notes;
            row.VisitLat = s.VisitLat;
            row.VisitLng = s.VisitLng;
            row.PhotoMediaIds = [.. s.Photos];
            row.DecidedBy = s.DecidedBy;
            row.DecidedAt = s.DecidedAt;
        }
    }

    private void SaveDocuments(LockedStates locked, VerificationState st)
    {
        var replaced = st.NewDocuments.Select(d => d.ItemType).ToHashSet(StringComparer.Ordinal);
        foreach (var row in locked.Documents.Where(d => d.ProviderId == st.ProviderId && replaced.Contains(d.ItemType)))
        {
            row.Current = false;
        }
        foreach (var d in st.NewDocuments)
        {
            db.Add(new VerificationDocumentRecord
            {
                Id = d.Id,
                ProviderId = st.ProviderId,
                ItemType = d.ItemType,
                Kind = d.Kind,
                MediaId = d.MediaId,
                Current = true,
                CreatedAt = d.CreatedAt,
            });
        }
    }

    private void SaveNid(LockedStates locked, VerificationState st, DateTimeOffset now)
    {
        if (!st.NidChanged || st.NidCiphertext is null || st.NidHash is null)
        {
            return;
        }
        if (!locked.Nids.TryGetValue(st.ProviderId, out var row))
        {
            row = new NidRecord { ProviderId = st.ProviderId, NidCiphertext = st.NidCiphertext, NidHash = st.NidHash };
            db.Add(row);
            locked.Nids[st.ProviderId] = row;
        }
        row.NidCiphertext = st.NidCiphertext;
        row.NidHash = st.NidHash;
        row.UpdatedAt = now;
    }
}
