using PAO.Core.Areas.Verification.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>Edits a merchant's state in place and returns the events to publish with it.</summary>
public delegate IEnumerable<IDomainEvent> StateChange(VerificationState state);

/// <summary>Changes merchant states under their row locks and keeps their levels current.</summary>
public sealed class VerificationStates(VerificationStateRepository repository, IClock clock, IIdGenerator ids)
{
    /// <summary>The time changes are stamped with.</summary>
    public DateTimeOffset Now => clock.Now;

    /// <summary>A new id.</summary>
    public Guid NewId() => ids.NewId();

    /// <summary>
    /// Applies `change` to one merchant and recomputes the level in the same transaction,
    /// publishing ProviderLevelChanged with `reason` whenever it moves (PRD §6.1). A null
    /// `reason` leaves the level alone.
    /// </summary>
    public async Task<VerificationState> Change(Guid providerId, string? reason, StateChange change, CancellationToken cancellationToken) =>
        (await ChangeMany([providerId], reason, change, cancellationToken))[0];

    /// <summary><see cref="Change"/> for many merchants at once, loaded and saved together.</summary>
    public async Task<IReadOnlyList<VerificationState>> ChangeMany(
        IReadOnlyCollection<Guid> providerIds, string? reason, StateChange change, CancellationToken cancellationToken)
    {
        var locked = await repository.LoadForUpdate(providerIds, cancellationToken);
        var events = new List<(Guid, IDomainEvent)>();
        foreach (var st in locked.States)
        {
            events.AddRange(change(st).Select(e => (st.ProviderId, e)));
            if (reason is not null && VerificationRules.Recalculate(st) is { } from)
            {
                events.Add((st.ProviderId, new ProviderLevelChanged { ProviderId = st.ProviderId, From = from, To = st.Level, Reason = reason }));
            }
        }
        await repository.Save(locked, events, cancellationToken);
        return locked.States;
    }

    /// <summary>The merchant's state for reading.</summary>
    public Task<VerificationState> Load(Guid providerId, CancellationToken cancellationToken) => repository.Load(providerId, cancellationToken);
}
