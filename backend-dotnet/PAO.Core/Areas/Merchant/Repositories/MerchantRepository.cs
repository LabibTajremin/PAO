using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using PAO.EF;
using PAO.EF.Merchant;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Merchant.Repositories;

/// <summary>
/// Stores merchant profiles (`provider.providers`, `provider.provider_services`) on the
/// scope's context, so writes and their events join the command's transaction.
/// </summary>
public sealed class MerchantRepository(PaoDbContext db, OutboxWriter outbox, IClock clock, IMapper mapper)
{
    /// <summary>Creates an empty profile on first use.</summary>
    public Task Ensure(Guid id, string phone, DateTimeOffset at, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO provider.providers (id, phone, created_at, updated_at) VALUES ({id}, {phone}, {at}, {at})
        ON CONFLICT (id) DO NOTHING
        """, cancellationToken);

    /// <summary>The profile with its services; `provider.not_found` without one.</summary>
    public async Task<StoredMerchant> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<MerchantProfileRecord>().FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new DomainException(MerchantErrors.NotFound);
        var services = await ServicesOf([id], cancellationToken);
        return mapper.Map<MerchantRow, StoredMerchant>(new MerchantRow(row, services.GetValueOrDefault(id, [])));
    }

    /// <summary>Writes the profile fields and services (never the read-model copies), then `domainEvent` if any.</summary>
    public async Task Save(StoredMerchant m, IDomainEvent? domainEvent, CancellationToken cancellationToken)
    {
        Point? home = m.HomeBase is { } h ? new Point(h.Lng, h.Lat) { SRID = 4326 } : null;
        string? gender = m.Gender.Length == 0 ? null : m.Gender;
        var steps = m.StepsDone.ToArray();
        var now = clock.Now;
        // Other areas call in outside a command; the profile and its services still change together.
        await using var own = db.Database.CurrentTransaction is null ? await db.Database.BeginTransactionAsync(cancellationToken) : null;
        await db.Set<MerchantProfileRecord>().Where(r => r.Id == m.Id).ExecuteUpdateAsync(u => u
            .SetProperty(r => r.FullName, m.FullName).SetProperty(r => r.DateOfBirth, m.DateOfBirth).SetProperty(r => r.Gender, gender)
            .SetProperty(r => r.PresentAddress, m.PresentAddress).SetProperty(r => r.PermanentAddress, m.PermanentAddress)
            .SetProperty(r => r.Bio, m.Bio).SetProperty(r => r.PhotoMediaId, m.PhotoMediaId).SetProperty(r => r.ExperienceYears, m.ExperienceYears)
            .SetProperty(r => r.Language, m.Language).SetProperty(r => r.HomeBase, home).SetProperty(r => r.WorkingRadiusM, m.WorkingRadiusM)
            .SetProperty(r => r.EmergencyName, m.Emergency.Name).SetProperty(r => r.EmergencyRelation, m.Emergency.Relation)
            .SetProperty(r => r.EmergencyPhone, m.Emergency.Phone).SetProperty(r => r.EmergencyVerifiedAt, m.Emergency.VerifiedAt)
            .SetProperty(r => r.CocVersion, m.CocVersion).SetProperty(r => r.CocAcceptedAt, m.CocAcceptedAt)
            .SetProperty(r => r.StepsDone, steps).SetProperty(r => r.SubmittedAt, m.SubmittedAt).SetProperty(r => r.UpdatedAt, now),
            cancellationToken);
        await db.Set<MerchantServiceRecord>().Where(s => s.ProviderId == m.Id).ExecuteDeleteAsync(cancellationToken);
        db.Set<MerchantServiceRecord>().AddRange(m.ServiceIds.Select(s => new MerchantServiceRecord { ProviderId = m.Id, ServiceId = s }));
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
        if (domainEvent is not null)
        {
            await Publish(m.Id, domainEvent, cancellationToken);
        }
        if (own is not null)
        {
            await own.CommitAsync(cancellationToken);
        }
    }

    /// <summary>Stores an event without changing the profile.</summary>
    public Task Publish(Guid id, IDomainEvent domainEvent, CancellationToken cancellationToken) =>
        outbox.Write(db, Schemas.Merchant, id.ToString(), domainEvent, cancellationToken);

    /// <summary>Active merchants at or above `minLevel` among `ids`, in one query; distances are 0.</summary>
    public async Task<IReadOnlyList<MerchantCandidate>> Candidates(IReadOnlyCollection<Guid> ids, int minLevel, CancellationToken cancellationToken)
    {
        var rows = await db.Set<MerchantProfileRecord>()
            .Where(m => ids.Contains(m.Id) && m.AccountStatus == "active" && m.Level >= minLevel).ToListAsync(cancellationToken);
        return mapper.MapAll<MerchantProfileRecord, MerchantCandidate>(rows);
    }

    /// <summary>Merchants for the admin console, newest first; `Online` is left for presence.</summary>
    public async Task<IReadOnlyList<MerchantRecord>> Search(MerchantQuery q, CancellationToken cancellationToken)
    {
        var pattern = SqlLike.Contains(q.Text);
        string? status = q.Status.Length == 0 ? null : q.Status;
        var afterAt = q.AfterAt?.ToUniversalTime();
        var afterId = q.AfterId ?? Guid.Empty;
        var rows = await db.Set<MerchantProfileRecord>().FromSql($"""
            SELECT * FROM provider.providers
            WHERE ({q.Id}::uuid IS NULL OR id = {q.Id}::uuid)
              AND ({pattern} = '' OR lower(full_name) LIKE {pattern} OR phone LIKE {pattern})
              AND ({status}::text IS NULL
                   OR (CASE WHEN account_status = 'active' AND level = 0 THEN 'pending' ELSE account_status END) = {status}::text)
              AND ({q.Level}::int IS NULL OR level = {q.Level}::int)
              AND ({q.Flagged}::bool IS NULL OR flagged_for_review = {q.Flagged}::bool)
              AND ({afterAt}::timestamptz IS NULL OR (created_at, id) < ({afterAt}::timestamptz, {afterId}))
            ORDER BY created_at DESC, id DESC
            LIMIT {q.Limit}
            """).ToListAsync(cancellationToken);
        var services = await ServicesOf([.. rows.Select(r => r.Id)], cancellationToken);
        return mapper.MapAll<MerchantRow, MerchantRecord>(rows.Select(r => new MerchantRow(r, services.GetValueOrDefault(r.Id, []))));
    }

    /// <summary>The services of each of `ids` that has a profile, in two queries; ids without one are absent.</summary>
    public async Task<IReadOnlyDictionary<Guid, IReadOnlyList<Guid>>> ServicesOfExisting(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken)
    {
        var existing = await db.Set<MerchantProfileRecord>().Where(m => ids.Contains(m.Id)).Select(m => m.Id).ToListAsync(cancellationToken);
        var services = await ServicesOf(existing, cancellationToken);
        return existing.ToDictionary(id => id, id => services.GetValueOrDefault(id, []));
    }

    private async Task<IReadOnlyDictionary<Guid, IReadOnlyList<Guid>>> ServicesOf(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken)
    {
        var rows = await db.Set<MerchantServiceRecord>().Where(s => ids.Contains(s.ProviderId))
            .OrderBy(s => s.ServiceId).ToListAsync(cancellationToken);
        return BatchLoader.GroupBy(rows, s => s.ProviderId).ToDictionary(g => g.Key, g => (IReadOnlyList<Guid>)[.. g.Value.Select(s => s.ServiceId)]);
    }
}
