using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Identity.Services.Shared;

/// <summary>
/// What other areas may ask of the Identity area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IIdentitySharedService
{
    /// <summary>Returns an account by id, or throws `identity.account_not_found`.</summary>
    Task<Account> GetAccount(Guid accountId, CancellationToken cancellationToken);

    /// <summary>Reports whether the account currently holds the role.</summary>
    Task<bool> HasRole(Guid accountId, string role, CancellationToken cancellationToken);

    /// <summary>Suspends, bans or reinstates an account. Banning blocks the phone number, revokes every session and publishes AccountStatusChanged (PRD §6.4).</summary>
    Task<Account> SetAccountStatus(SetAccountStatusInput input, CancellationToken cancellationToken);

    /// <summary>Sends a one-time code to a phone that is not the caller's own account, such as a merchant's emergency contact (PRD §6.2 item 6).</summary>
    Task SendPhoneCode(string phone, string purpose, CancellationToken cancellationToken);

    /// <summary>Verifies a code sent by <see cref="SendPhoneCode"/>.</summary>
    Task CheckPhoneCode(string phone, string purpose, string code, CancellationToken cancellationToken);
}
