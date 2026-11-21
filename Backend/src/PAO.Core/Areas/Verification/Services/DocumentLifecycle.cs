using PAO.Core.Areas.Verification.Repositories;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>Expiry, reminders, account blocking and the retention purge (PRD §6.4, §6.6, ADR-0023).</summary>
public sealed class DocumentLifecycle(
    VerificationStates states, VerificationRepository repository, VerificationStateRepository stateRepository,
    ClosedAccountRepository closures, VerificationPeers peers)
{
    /// <summary>When merchants hear that a document is about to expire, in days (P-11).</summary>
    public static readonly IReadOnlyList<int> ReminderDays = [30, 7, 1];

    /// <summary>Expires approved items past their date as of `at`; levels drop with them. Returns how many merchants changed.</summary>
    public async Task<int> Expire(DateTimeOffset at, CancellationToken cancellationToken)
    {
        var due = await repository.ExpiredBy(at, cancellationToken);
        if (due.Count == 0)
        {
            return 0;
        }
        await states.ChangeMany(due, "document_expired", st =>
        {
            var expired = st.Items.Values.Where(it => VerificationRules.HasExpired(it, at)).ToList();
            foreach (var it in expired)
            {
                st.Items[it.Type] = it with { Status = ItemStatus.Expired };
            }
            return expired.Select(it => new DocumentExpired { ProviderId = st.ProviderId, Item = it.Type });
        }, cancellationToken);
        return due.Count;
    }

    /// <summary>Sends each reminder once per document and threshold. Returns how many were sent.</summary>
    public async Task<int> Remind(CancellationToken cancellationToken)
    {
        var now = states.Now;
        var sent = 0;
        foreach (var days in ReminderDays)
        {
            var items = await repository.ExpiringBetween(now.AddDays(days - 1), now.AddDays(days), cancellationToken);
            var fresh = items.Count == 0 ? [] : await repository.RecordReminders(items, days, now, cancellationToken);
            var events = fresh.Select(it => (it.ProviderId, (IDomainEvent)new DocumentExpiring { ProviderId = it.ProviderId, Item = it.ItemType, DaysLeft = days })).ToList();
            await stateRepository.WriteEvents(events, cancellationToken);
            sent += events.Count;
        }
        return sent;
    }

    /// <summary>
    /// Blocks suspended and banned merchants and unblocks reinstated ones; a ban also puts
    /// their NID on the block list.
    /// </summary>
    public async Task AccountStatusChanged(Guid id, string status, CancellationToken cancellationToken)
    {
        await repository.SetBlocked(id, status != "active", states.Now, cancellationToken);
        if (status == "banned")
        {
            await repository.BlockNid(id, "account banned", cancellationToken);
        }
    }

    /// <summary>Starts the retention clock of a deleted account.</summary>
    public Task Closed(Guid id, CancellationToken cancellationToken) => closures.Record(id, states.Now, cancellationToken);

    /// <summary>Purges accounts closed longer than the retention setting; returns how many.</summary>
    public async Task<int> PurgeExpired(CancellationToken cancellationToken)
    {
        var settings = await peers.Settings(cancellationToken);
        var due = await closures.ClosedBefore(states.Now - settings.DocumentRetention, cancellationToken);
        if (due.Count == 0)
        {
            return 0;
        }
        // Files first: if a delete fails, the records still point at what is left.
        foreach (var photo in await closures.Level2Photos(due, cancellationToken))
        {
            await peers.DeleteFile(photo, cancellationToken);
        }
        foreach (var id in due)
        {
            await peers.DeleteOwnedFiles(id, cancellationToken);
        }
        await closures.Purge(due, cancellationToken);
        return due.Count;
    }
}
