using System.Text;
using Microsoft.EntityFrameworkCore;
using PAO.Core.Areas.Identity.Services;
using PAO.EF;
using PAO.EF.Identity;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Infrastructure.Rbac;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using Account = PAO.EF.Identity.Account;

namespace PAO.Core.Areas.Identity.Repositories;

/// <summary>The <see cref="IIdentityRepository"/> on the scope's <see cref="PaoDbContext"/>; reads here, writes in the other part.</summary>
public sealed partial class IdentityRepository(PaoDbContext db, IClock clock, DataCipher cipher, OutboxWriter outbox) : IIdentityRepository
{
    private sealed record AccountRow(Account Account, List<string> Roles);

    /// <inheritdoc />
    public async Task<AccountRecord> AccountById(Guid id, CancellationToken cancellationToken) =>
        ToRecord(Found(await WithRoles(db.Set<Account>().Where(a => a.Id == id)).FirstOrDefaultAsync(cancellationToken)));

    /// <inheritdoc />
    public async Task<AccountRecord> AccountByPhone(string phone, CancellationToken cancellationToken) =>
        ToRecord(Found(await WithRoles(db.Set<Account>().Where(a => a.Phone == phone)).FirstOrDefaultAsync(cancellationToken)));

    /// <inheritdoc />
    public async Task<AdminRecord> AdminByEmail(string email, CancellationToken cancellationToken)
    {
        var lower = email.Trim().ToLowerInvariant();
        var row = await WithRoles(db.Set<Account>().Where(a => a.Email!.ToLower() == lower)).FirstOrDefaultAsync(cancellationToken);
        return await WithCredentials(ToRecord(Found(row)), cancellationToken);
    }

    /// <inheritdoc />
    public async Task<AdminRecord> AdminById(Guid id, CancellationToken cancellationToken) =>
        await WithCredentials(await AccountById(id, cancellationToken), cancellationToken);

    /// <inheritdoc />
    public async Task<IReadOnlyList<AdminRecord>> ListAdmins(CancellationToken cancellationToken)
    {
        var rows = await (
            from c in db.Set<AdminCredentials>()
            join a in db.Set<Account>() on c.AccountId equals a.Id
            where a.DeletedAt == null
            orderby a.Email
            select new
            {
                Credentials = c,
                Row = new AccountRow(a, db.Set<AccountRole>().Where(r => r.AccountId == a.Id).OrderBy(r => r.Role).Select(r => r.Role).ToList()),
            }).ToListAsync(cancellationToken);
        return [.. rows.Select(r => ToAdmin(ToRecord(r.Row), r.Credentials))];
    }

    /// <inheritdoc />
    public Task<bool> IsPhoneBlocked(string phone, CancellationToken cancellationToken) =>
        db.Set<BlockedPhone>().AnyAsync(b => b.Phone == phone, cancellationToken);

    /// <inheritdoc />
    public async Task<IReadOnlyList<string>> ListRoles(CancellationToken cancellationToken) =>
        await db.Roles.OrderBy(r => r.Name).Select(r => r.Name).ToListAsync(cancellationToken);

    /// <inheritdoc />
    public async Task<IReadOnlyDictionary<string, Grants>> AllGrants(CancellationToken cancellationToken)
    {
        var permissions = await db.RolePermissions.OrderBy(p => p.Permission).ToListAsync(cancellationToken);
        var screens = await db.RoleScreens.OrderBy(s => s.ScreenId).ToListAsync(cancellationToken);
        var byRole = BatchLoader.GroupBy(permissions, p => p.Role);
        var screensByRole = BatchLoader.GroupBy(screens, s => s.Role);
        return byRole.Keys.Union(screensByRole.Keys).ToDictionary(
            role => role,
            role => new Grants(
                [.. byRole.GetValueOrDefault(role, []).Select(p => p.Permission)],
                [.. screensByRole.GetValueOrDefault(role, []).Select(s => s.ScreenId)]));
    }

    /// <inheritdoc />
    public async Task<(IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens)> Catalogue(CancellationToken cancellationToken)
    {
        var permissions = await db.Permissions.OrderBy(p => p.Name).Select(p => p.Name).ToListAsync(cancellationToken);
        var screens = await db.Screens.OrderBy(s => s.Id).Select(s => s.Id).ToListAsync(cancellationToken);
        return (permissions, screens);
    }

    /// <inheritdoc />
    public Task Publish(Guid aggregateId, IDomainEvent domainEvent, CancellationToken cancellationToken) =>
        outbox.Write(db, Schemas.Identity, aggregateId.ToString(), domainEvent, cancellationToken);

    private IQueryable<AccountRow> WithRoles(IQueryable<Account> accounts) =>
        accounts.Select(a => new AccountRow(a, db.Set<AccountRole>().Where(r => r.AccountId == a.Id).OrderBy(r => r.Role).Select(r => r.Role).ToList()));

    private async Task<AdminRecord> WithCredentials(AccountRecord account, CancellationToken cancellationToken)
    {
        var credentials = await db.Set<AdminCredentials>().FirstOrDefaultAsync(c => c.AccountId == account.Id, cancellationToken);
        return ToAdmin(account, Found(credentials));
    }

    private static T Found<T>(T? row)
        where T : class => row ?? throw new DomainException(IdentityReasons.AccountNotFound);

    private static AccountRecord ToRecord(AccountRow row) => new()
    {
        Id = row.Account.Id,
        Phone = row.Account.Phone ?? string.Empty,
        Email = row.Account.Email ?? string.Empty,
        Name = row.Account.Name,
        Status = row.Account.Status,
        Roles = row.Roles,
        CreatedAt = row.Account.CreatedAt,
        DeletedAt = row.Account.DeletedAt,
    };

    private AdminRecord ToAdmin(AccountRecord a, AdminCredentials c) => new()
    {
        Id = a.Id,
        Phone = a.Phone,
        Email = a.Email,
        Name = a.Name,
        Status = a.Status,
        Roles = a.Roles,
        CreatedAt = a.CreatedAt,
        DeletedAt = a.DeletedAt,
        PasswordHash = c.PasswordHash,
        MustChangePassword = c.MustChangePassword,
        TotpSecret = c.TotpSecretEnc is null ? string.Empty : Encoding.UTF8.GetString(cipher.Decrypt(c.TotpSecretEnc)),
        TotpEnrolled = c.TotpEnrolled,
        FailedAttempts = c.FailedAttempts,
        LockedUntil = c.LockedUntil,
        Active = c.Active,
        LastLoginAt = c.LastLoginAt,
    };
}
