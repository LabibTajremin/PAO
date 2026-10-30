using PAO.Core.Areas.Merchant.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>Loads and saves profiles for the enrolment and profile use cases.</summary>
public sealed class MerchantProfiles(MerchantRepository repository, MerchantPeers peers, IClock clock)
{
    /// <summary>The clock the use cases stamp times with.</summary>
    public IClock Clock => clock;

    /// <summary>The profile; `provider.not_found` without one.</summary>
    public Task<StoredMerchant> Get(Guid id, CancellationToken cancellationToken) => repository.Get(id, cancellationToken);

    /// <summary>The profile, creating an empty one on the first enrolment call.</summary>
    public async Task<StoredMerchant> Load(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            return await repository.Get(id, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == MerchantErrors.NotFound)
        {
            await repository.Ensure(id, await Phone(id, cancellationToken), clock.Now, cancellationToken);
            return await repository.Get(id, cancellationToken);
        }
    }

    /// <summary>The account phone; a token whose account no longer exists has no merchant to create.</summary>
    private async Task<string> Phone(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            return await peers.Phone(id, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == IdentityErrors.AccountNotFound)
        {
            throw new DomainException(MerchantErrors.NotFound, error);
        }
    }

    /// <summary>
    /// Loads the profile, applies `change`, marks `step` done (when given) and saves, with
    /// `EnrolmentStepSaved` for the profile steps.
    /// </summary>
    public async Task<EnrolmentStatus> Update(Guid id, string? step, Func<StoredMerchant, Task<StoredMerchant>> change, CancellationToken cancellationToken)
    {
        var m = await change(await Load(id, cancellationToken));
        EnrolmentStepSaved? saved = null;
        if (step is not null)
        {
            m = m with { StepsDone = EnrolmentRules.WithStep(m.StepsDone, step) };
            saved = EnrolmentRules.ProfileSteps.Contains(step) ? new EnrolmentStepSaved { ProviderId = id, Step = step } : null;
        }
        await repository.Save(m, saved, cancellationToken);
        return EnrolmentRules.ProgressOf(m);
    }

    /// <summary>The same as the other overload, for changes that need no awaiting.</summary>
    public Task<EnrolmentStatus> Update(Guid id, string? step, Func<StoredMerchant, StoredMerchant> change, CancellationToken cancellationToken) =>
        Update(id, step, m => Task.FromResult(change(m)), cancellationToken);
}
