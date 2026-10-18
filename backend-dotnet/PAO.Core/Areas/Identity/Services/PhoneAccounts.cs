using PAO.Core.Areas.Identity.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>Finds people by phone and registers newcomers, publishing what changed.</summary>
public sealed class PhoneAccounts(IIdentityRepository repository, IClock clock, IIdGenerator ids)
{
    /// <summary>The account with this phone, or null.</summary>
    public async Task<AccountRecord?> Find(string phone, CancellationToken cancellationToken)
    {
        try
        {
            return await repository.AccountByPhone(phone, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == IdentityReasons.AccountNotFound)
        {
            return null;
        }
    }

    /// <summary>Creates an active account holding `role`.</summary>
    public async Task<AccountRecord> Register(string phone, string role, CancellationToken cancellationToken)
    {
        var account = new AccountRecord { Id = ids.NewId(), Phone = phone, Status = AccountStatus.Active, Roles = [role], CreatedAt = clock.Now };
        await repository.CreateAccount(account, cancellationToken);
        await repository.GrantRole(account.Id, role, cancellationToken);
        await repository.Publish(account.Id, new AccountCreated { AccountId = account.Id, Phone = phone, Role = role }, cancellationToken);
        return account;
    }

    /// <summary>Adds `role` unless the account holds it or may not sign in anyway.</summary>
    public async Task<AccountRecord> AddRole(AccountRecord account, string role, CancellationToken cancellationToken)
    {
        if (account.Roles.Contains(role) || IdentityRules.SignInRefusal(account) is not null)
        {
            return account;
        }
        await repository.GrantRole(account.Id, role, cancellationToken);
        await repository.Publish(account.Id, new RoleGranted { AccountId = account.Id, Role = role }, cancellationToken);
        return account with { Roles = [.. account.Roles, role] };
    }
}

/// <summary>Suspends, bans and reinstates accounts (A-05).</summary>
public sealed class AccountStatusChanger(IIdentityRepository repository, Sessions sessions)
{
    /// <summary>
    /// Changes the status. Banning blocks the phone so it cannot sign up again (PRD §6.4);
    /// suspending or banning ends every session.
    /// </summary>
    public async Task<AccountRecord> Set(SetAccountStatusInput input, CancellationToken cancellationToken)
    {
        var account = await repository.AccountById(input.AccountId, cancellationToken);
        if (!IdentityRules.CanChangeStatus(account, input.Status))
        {
            throw new DomainException(IdentityReasons.StatusChange);
        }
        await repository.UpdateStatus(account.Id, input.Status, cancellationToken);
        await UpdatePhoneBlock(account, input, cancellationToken);
        await repository.Publish(account.Id, new AccountStatusChanged
        {
            AccountId = account.Id,
            From = account.Status,
            To = input.Status,
            Reason = input.Reason,
            ActorId = input.ActorId,
            Roles = account.Roles,
        }, cancellationToken);
        if (input.Status != AccountStatus.Active)
        {
            await sessions.RevokeAll(account.Id);
        }
        return account with { Status = input.Status };
    }

    private async Task UpdatePhoneBlock(AccountRecord account, SetAccountStatusInput input, CancellationToken cancellationToken)
    {
        if (account.Phone.Length == 0)
        {
            return;
        }
        if (input.Status == AccountStatus.Banned)
        {
            await repository.BlockPhone(account.Phone, input.Reason, cancellationToken);
        }
        else if (account.Status == AccountStatus.Banned)
        {
            await repository.UnblockPhone(account.Phone, cancellationToken);
        }
    }
}
