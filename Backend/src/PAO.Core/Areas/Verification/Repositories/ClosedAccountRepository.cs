using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Verification;

namespace PAO.Core.Areas.Verification.Repositories;

/// <summary>`verification.closed_accounts` and the purge of the merchants' records (ADR-0023).</summary>
public sealed class ClosedAccountRepository(PaoDbContext db)
{
    /// <summary>The largest number of accounts one purge run handles; the next night takes the rest.</summary>
    public const int Batch = 500;

    /// <summary>Remembers the first closure; a redelivered event keeps the original time.</summary>
    public Task Record(Guid providerId, DateTimeOffset closedAt, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO verification.closed_accounts (provider_id, closed_at) VALUES ({providerId}, {closedAt})
        ON CONFLICT (provider_id) DO NOTHING
        """, cancellationToken);

    /// <summary>Accounts closed before `cutoff`, oldest first.</summary>
    public Task<List<Guid>> ClosedBefore(DateTimeOffset cutoff, CancellationToken cancellationToken) =>
        db.Set<ClosedAccountRecord>().Where(c => c.ClosedAt < cutoff).OrderBy(c => c.ClosedAt).Take(Batch)
            .Select(c => c.ProviderId).ToListAsync(cancellationToken);

    /// <summary>The Level 2 visit photos kept for the merchants; verifiers uploaded them.</summary>
    public async Task<List<Guid>> Level2Photos(IReadOnlyCollection<Guid> providerIds, CancellationToken cancellationToken) =>
        (await db.Set<Level2SessionRecord>().Where(s => providerIds.Contains(s.ProviderId)).Select(s => s.PhotoMediaIds).ToListAsync(cancellationToken))
            .SelectMany(p => p).ToList();

    /// <summary>Deletes every verification record of the merchants, closures included.</summary>
    public async Task Purge(IReadOnlyCollection<Guid> providerIds, CancellationToken cancellationToken)
    {
        await db.Set<VerificationItemRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<VerificationDocumentRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<NidRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<Level2SessionRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<ExpiryReminderRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<VerificationLevelRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
        await db.Set<ClosedAccountRecord>().Where(r => providerIds.Contains(r.ProviderId)).ExecuteDeleteAsync(cancellationToken);
    }
}
