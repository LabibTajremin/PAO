using PAO.Infrastructure.Rbac;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Identity.Repositories;

/// <summary>
/// Identity data in the `identity` schema. Missing accounts throw `identity.account_not_found`.
/// Writes join the command's transaction; <see cref="Publish"/> adds to the identity outbox.
/// </summary>
public interface IIdentityRepository
{
    /// <summary>The account by id.</summary>
    Task<AccountRecord> AccountById(Guid id, CancellationToken cancellationToken);
    /// <summary>The account by E.164 phone.</summary>
    Task<AccountRecord> AccountByPhone(string phone, CancellationToken cancellationToken);
    /// <summary>The admin by email, case-insensitively; an account without credentials is no admin.</summary>
    Task<AdminRecord> AdminByEmail(string email, CancellationToken cancellationToken);
    /// <summary>The admin by id.</summary>
    Task<AdminRecord> AdminById(Guid id, CancellationToken cancellationToken);
    /// <summary>Every live admin, by email.</summary>
    Task<IReadOnlyList<AdminRecord>> ListAdmins(CancellationToken cancellationToken);
    /// <summary>Whether the phone belongs to a banned identity.</summary>
    Task<bool> IsPhoneBlocked(string phone, CancellationToken cancellationToken);
    /// <summary>Every role name, sorted.</summary>
    Task<IReadOnlyList<string>> ListRoles(CancellationToken cancellationToken);
    /// <summary>The grants of every role, in two queries.</summary>
    Task<IReadOnlyDictionary<string, Grants>> AllGrants(CancellationToken cancellationToken);
    /// <summary>Every known permission and screen id.</summary>
    Task<(IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens)> Catalogue(CancellationToken cancellationToken);

    /// <summary>Inserts an account (not its roles).</summary>
    Task CreateAccount(AccountRecord account, CancellationToken cancellationToken);
    /// <summary>Adds a role unless held.</summary>
    Task GrantRole(Guid accountId, string role, CancellationToken cancellationToken);
    /// <summary>Replaces the account's roles.</summary>
    Task SetRoles(Guid accountId, IReadOnlyCollection<string> roles, CancellationToken cancellationToken);
    /// <summary>Changes the status.</summary>
    Task UpdateStatus(Guid accountId, string status, CancellationToken cancellationToken);
    /// <summary>Blocks a phone from signing up again.</summary>
    Task BlockPhone(string phone, string reason, CancellationToken cancellationToken);
    /// <summary>Lifts a phone block.</summary>
    Task UnblockPhone(string phone, CancellationToken cancellationToken);
    /// <summary>Erases phone, email and name and marks the account deleted.</summary>
    Task AnonymiseAccount(Guid accountId, CancellationToken cancellationToken);
    /// <summary>Adds credentials that force a password change.</summary>
    Task CreateAdminCredentials(Guid accountId, string passwordHash, CancellationToken cancellationToken);
    /// <summary>Saves the admin's credentials; the TOTP secret is encrypted.</summary>
    Task SaveAdmin(AdminRecord admin, CancellationToken cancellationToken);
    /// <summary>Replaces a role's permissions and screens.</summary>
    Task ReplaceRole(RoleDefinitionRecord role, CancellationToken cancellationToken);
    /// <summary>Adds an event to the identity outbox.</summary>
    Task Publish(Guid aggregateId, IDomainEvent domainEvent, CancellationToken cancellationToken);
}
