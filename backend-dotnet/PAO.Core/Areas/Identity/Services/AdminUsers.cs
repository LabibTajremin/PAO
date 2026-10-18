using PAO.Core.Areas.Identity.Repositories;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>Operations staff accounts (A-01, A-10): invites and the seeded demo admins.</summary>
public sealed class AdminUsers(IIdentityRepository repository, IClock clock, IIdGenerator ids)
{
    /// <summary>
    /// Creates an admin with a one-time temporary password; the first login forces a
    /// password change and TOTP enrolment.
    /// </summary>
    public async Task<InvitedAdmin> Create(string rawEmail, string name, IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        if (!IdentityRules.IsAdminRoleSet(roles))
        {
            throw new DomainException(IdentityReasons.RoleInvalid);
        }
        var email = rawEmail.Trim().ToLowerInvariant();
        if (await Exists(email, cancellationToken))
        {
            throw new DomainException(IdentityReasons.EmailTaken);
        }
        var temporaryPassword = RandomSecrets.Token(12);
        var admin = new AdminRecord
        {
            Id = ids.NewId(),
            Email = email,
            Name = name,
            Status = AccountStatus.Active,
            Roles = [.. roles],
            CreatedAt = clock.Now,
            PasswordHash = await SecretHasher.Hash(temporaryPassword, Argon2Params.Password),
            MustChangePassword = true,
        };
        await repository.CreateAccount(admin, cancellationToken);
        await repository.SetRoles(admin.Id, admin.Roles, cancellationToken);
        await repository.CreateAdminCredentials(admin.Id, admin.PasswordHash, cancellationToken);
        return new InvitedAdmin(admin, temporaryPassword);
    }

    /// <summary>
    /// Creates a demo admin with a known password unless the email exists; the seed uses it
    /// for dev and staging. TOTP enrolment still happens at the first login.
    /// </summary>
    public async Task Ensure(string email, string name, IReadOnlyCollection<string> roles, string password, CancellationToken cancellationToken)
    {
        if (await Exists(email.Trim().ToLowerInvariant(), cancellationToken))
        {
            return;
        }
        var created = await Create(email, name, roles, cancellationToken);
        var hash = await SecretHasher.Hash(password, Argon2Params.Password);
        await repository.SaveAdmin(created.Admin with { PasswordHash = hash, MustChangePassword = false }, cancellationToken);
    }

    private async Task<bool> Exists(string email, CancellationToken cancellationToken)
    {
        try
        {
            await repository.AdminByEmail(email, cancellationToken);
            return true;
        }
        catch (DomainException error) when (error.Reason == IdentityReasons.AccountNotFound)
        {
            return false;
        }
    }
}
