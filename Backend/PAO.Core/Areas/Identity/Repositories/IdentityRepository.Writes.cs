using System.Text;
using Microsoft.EntityFrameworkCore;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Identity.Repositories;

// The writes, in the SQL the NestJS queries ran; they join the command's transaction.
public sealed partial class IdentityRepository
{
    /// <inheritdoc />
    public Task CreateAccount(AccountRecord account, CancellationToken cancellationToken)
    {
        var phone = account.Phone.Length == 0 ? null : account.Phone;
        var email = account.Email.Length == 0 ? null : account.Email.Trim().ToLowerInvariant();
        var at = account.CreatedAt.ToUniversalTime();
        return db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.accounts (id, phone, email, name, status, created_at, updated_at) VALUES ({account.Id}, {phone}, {email}, {account.Name}, {account.Status}, {at}, {at})",
            cancellationToken);
    }

    /// <inheritdoc />
    public Task GrantRole(Guid accountId, string role, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.account_roles (account_id, role, granted_at) VALUES ({accountId}, {role}, {Now}) ON CONFLICT DO NOTHING",
            cancellationToken);

    /// <inheritdoc />
    public async Task SetRoles(Guid accountId, IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlInterpolatedAsync($"DELETE FROM identity.account_roles WHERE account_id = {accountId}", cancellationToken);
        var names = roles.ToArray();
        await db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.account_roles (account_id, role, granted_at) SELECT {accountId}, unnest({names}::text[]), {Now}",
            cancellationToken);
    }

    /// <inheritdoc />
    public Task UpdateStatus(Guid accountId, string status, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync(
            $"UPDATE identity.accounts SET status = {status}, updated_at = {Now} WHERE id = {accountId}", cancellationToken);

    /// <inheritdoc />
    public Task BlockPhone(string phone, string reason, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.blocked_phones (phone, reason, blocked_at) VALUES ({phone}, {reason}, {Now}) ON CONFLICT (phone) DO NOTHING",
            cancellationToken);

    /// <inheritdoc />
    public Task UnblockPhone(string phone, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync($"DELETE FROM identity.blocked_phones WHERE phone = {phone}", cancellationToken);

    /// <inheritdoc />
    public Task AnonymiseAccount(Guid accountId, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync(
            $"UPDATE identity.accounts SET phone = NULL, email = NULL, name = '', deleted_at = {Now}, updated_at = {Now} WHERE id = {accountId}",
            cancellationToken);

    /// <inheritdoc />
    public Task CreateAdminCredentials(Guid accountId, string passwordHash, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.admin_credentials (account_id, password_hash, must_change_password) VALUES ({accountId}, {passwordHash}, true)",
            cancellationToken);

    /// <inheritdoc />
    public Task SaveAdmin(AdminRecord admin, CancellationToken cancellationToken)
    {
        var secret = admin.TotpSecret.Length == 0 ? null : cipher.Encrypt(Encoding.UTF8.GetBytes(admin.TotpSecret));
        var lockedUntil = admin.LockedUntil?.ToUniversalTime();
        var lastLogin = admin.LastLoginAt?.ToUniversalTime();
        return db.Database.ExecuteSqlInterpolatedAsync(
            $"""
            UPDATE identity.admin_credentials
            SET password_hash = {admin.PasswordHash}, must_change_password = {admin.MustChangePassword}, totp_secret_enc = {secret},
                totp_enrolled = {admin.TotpEnrolled}, failed_attempts = {admin.FailedAttempts}, locked_until = {lockedUntil},
                active = {admin.Active}, last_login_at = {lastLogin}
            WHERE account_id = {admin.Id}
            """,
            cancellationToken);
    }

    /// <inheritdoc />
    public async Task ReplaceRole(RoleDefinitionRecord role, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlInterpolatedAsync($"DELETE FROM identity.role_permissions WHERE role = {role.Role}", cancellationToken);
        await db.Database.ExecuteSqlInterpolatedAsync($"DELETE FROM identity.role_screens WHERE role = {role.Role}", cancellationToken);
        var permissions = role.Permissions.ToArray();
        var screens = role.Screens.ToArray();
        await db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.role_permissions (role, permission) SELECT {role.Role}, unnest({permissions}::text[])", cancellationToken);
        await db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO identity.role_screens (role, screen_id) SELECT {role.Role}, unnest({screens}::text[])", cancellationToken);
    }

    private DateTimeOffset Now => clock.Now.ToUniversalTime();
}
