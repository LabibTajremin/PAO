using Microsoft.EntityFrameworkCore;
using PAO.Core.Areas.Merchant.Repositories;
using PAO.EF;
using PAO.EF.Merchant;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Merchant;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>
/// Keeps the read-model copies (level, status, rating, jobs) current and flags merchants
/// for review when quality thresholds are crossed (PRD §6.4, D13). Every method writes
/// through the event handler's context, so its changes commit with the processed-event row.
/// </summary>
public sealed class MerchantReadModel(IPresence presence, OutboxWriter outbox, IServiceScopeFactory scopes)
{
    private static readonly TimeSpan CancellationWindow = TimeSpan.FromDays(30);

    /// <summary>`verification.ProviderLevelChanged`: a drop below Level 1 takes the merchant offline.</summary>
    public async Task LevelChanged(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var id = Guid.Parse(p.Id("providerId"));
        var level = (int)p.Number("to");
        await Rows(db, id).ExecuteUpdateAsync(u => u.SetProperty(m => m.Level, level), cancellationToken);
        if (level < 1)
        {
            await Offline(db, id, "level_dropped", cancellationToken);
        }
    }

    /// <summary>`identity.AccountStatusChanged`: any status but active takes the merchant offline.</summary>
    public async Task StatusChanged(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var id = Guid.Parse(p.Id("accountId"));
        var status = p.Text("to");
        await Rows(db, id).ExecuteUpdateAsync(u => u.SetProperty(m => m.AccountStatus, status), cancellationToken);
        if (status != "active")
        {
            await Offline(db, id, $"account_{status}", cancellationToken);
        }
    }

    /// <summary>`identity.AccountDeleted`: offline, then the profile goes (PRD §11).</summary>
    public async Task Deleted(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var id = Guid.Parse(p.Id("accountId"));
        await Offline(db, id, "account_deleted", cancellationToken);
        await Rows(db, id).ExecuteDeleteAsync(cancellationToken);
    }

    /// <summary>`rating.ReviewSubmitted` about a merchant: copy the rating, flag it below the floor.</summary>
    public async Task ReviewSubmitted(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var id = Guid.Parse(p.Id("subjectId"));
        if (p.Text("subjectRole") != "provider")
        {
            return;
        }
        var average = p.Number("newAverage");
        var count = (int)p.Number("newCount");
        await Rows(db, id).ExecuteUpdateAsync(u => u.SetProperty(m => m.RatingAvg, average).SetProperty(m => m.RatingCount, count), cancellationToken);
        var settings = await Settings(cancellationToken);
        if (count >= settings.RatingMinJobs && average < settings.RatingFloor)
        {
            await Flag(db, id, "rating_below_floor", cancellationToken);
        }
    }

    /// <summary>`booking.BookingCompleted`: one more completed job.</summary>
    public Task BookingCompleted(PaoDbContext db, EventPayload p, CancellationToken cancellationToken) =>
        Rows(db, Guid.Parse(p.Id("providerId"))).ExecuteUpdateAsync(u => u.SetProperty(m => m.CompletedJobs, m => m.CompletedJobs + 1), cancellationToken);

    /// <summary>`booking.BookingCancelled` by the merchant after acceptance: counted over 30 days, flagged past the limit.</summary>
    public async Task BookingCancelled(PaoDbContext db, EventPayload p, DateTimeOffset at, CancellationToken cancellationToken)
    {
        var providerId = Guid.Parse(p.Id("providerId"));
        if (p.Text("by") != "provider" || !p.Flag("afterAcceptance"))
        {
            return;
        }
        var bookingId = Guid.Parse(p.Id("bookingId"));
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO provider.cancellations (booking_id, provider_id, at) VALUES ({bookingId}, {providerId}, {at.ToUniversalTime()})
            ON CONFLICT DO NOTHING
            """, cancellationToken);
        var since = at - CancellationWindow;
        var n = await db.Set<CancellationRecord>().CountAsync(c => c.ProviderId == providerId && c.At > since, cancellationToken);
        if (n > (await Settings(cancellationToken)).MaxProviderCancellations30d)
        {
            await Flag(db, providerId, "cancellations", cancellationToken);
        }
    }

    /// <summary>`admin.ComplaintResolved` as verified: flag the merchant it was against.</summary>
    public async Task ComplaintResolved(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var against = Guid.Parse(p.Id("againstId"));
        if (p.Flag("verified"))
        {
            await Flag(db, against, "verified_complaint", cancellationToken);
        }
    }

    private static IQueryable<MerchantProfileRecord> Rows(PaoDbContext db, Guid id) =>
        db.Set<MerchantProfileRecord>().Where(m => m.Id == id);

    private async Task<PAO.Lib.Areas.Admin.PlatformSettings> Settings(CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        return await scope.ServiceProvider.GetRequiredService<MerchantPeers>().Settings(cancellationToken);
    }

    /// <summary>Flags once; the first flag publishes `ProviderFlaggedForReview`.</summary>
    private async Task Flag(PaoDbContext db, Guid id, string reason, CancellationToken cancellationToken)
    {
        var flagged = await Rows(db, id).Where(m => !m.FlaggedForReview)
            .ExecuteUpdateAsync(u => u.SetProperty(m => m.FlaggedForReview, true).SetProperty(m => m.FlagReason, reason), cancellationToken);
        if (flagged == 1)
        {
            await outbox.Write(db, Schemas.Merchant, id.ToString(), new ProviderFlaggedForReview { ProviderId = id, Reason = reason }, cancellationToken);
        }
    }

    /// <summary>Events also arrive for accounts that never enrolled as merchants; those have nothing to take offline.</summary>
    private async Task Offline(PaoDbContext db, Guid id, string reason, CancellationToken cancellationToken)
    {
        if (!await Rows(db, id).AnyAsync(cancellationToken))
        {
            return;
        }
        var services = await db.Set<MerchantServiceRecord>().Where(s => s.ProviderId == id).Select(s => s.ServiceId).ToListAsync(cancellationToken);
        await presence.Offline(id, services);
        await outbox.Write(db, Schemas.Merchant, id.ToString(), new ProviderWentOffline { ProviderId = id, Reason = reason }, cancellationToken);
    }
}
