using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Sms;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.UnitTests.Areas.Identity;

/// <summary>Fails a named step on demand.</summary>
public abstract class Faulty
{
    public Dictionary<string, Exception> Faults { get; } = [];

    protected void Step(string name)
    {
        if (Faults.TryGetValue(name, out var error))
        {
            throw error;
        }
    }
}

public sealed class FakeRepository : Faulty, IIdentityRepository
{
    public Dictionary<Guid, AccountRecord> Accounts { get; } = [];
    public Dictionary<Guid, AdminRecord> Admins { get; } = [];
    public HashSet<string> Blocked { get; } = [];
    public List<IDomainEvent> Events { get; } = [];
    public Dictionary<string, Grants> Grants { get; } = new()
    {
        ["customer"] = new(["booking:create"], ["C01", "C07"]),
        ["provider"] = new(["job:respond"], ["M01", "M14", "M15"]),
        ["verifier"] = new(["verification:review"], ["A05"]),
    };
    public IReadOnlyList<string> AllPermissions { get; } = ["booking:create", "job:respond", "verification:review"];
    public IReadOnlyList<string> AllScreens { get; } = ["A01", "A05", "C01", "C07", "M01", "M14", "M15"];

    private static DomainException NotFound => new(IdentityReasons.AccountNotFound);

    public Task<AccountRecord> AccountById(Guid id, CancellationToken cancellationToken)
    {
        Step(nameof(AccountById));
        return Task.FromResult(Admins.GetValueOrDefault(id) ?? Accounts.GetValueOrDefault(id) ?? throw NotFound);
    }

    public Task<AccountRecord> AccountByPhone(string phone, CancellationToken cancellationToken)
    {
        Step(nameof(AccountByPhone));
        return Task.FromResult(Accounts.Values.FirstOrDefault(a => a.Phone == phone && phone.Length > 0) ?? throw NotFound);
    }

    public Task<AdminRecord> AdminByEmail(string email, CancellationToken cancellationToken)
    {
        Step(nameof(AdminByEmail));
        var lower = email.Trim().ToLowerInvariant();
        return Task.FromResult(Admins.Values.FirstOrDefault(a => a.Email == lower) ?? throw NotFound);
    }

    public Task<AdminRecord> AdminById(Guid id, CancellationToken cancellationToken)
    {
        Step(nameof(AdminById));
        return Task.FromResult(Admins.GetValueOrDefault(id) ?? throw NotFound);
    }

    public Task<IReadOnlyList<AdminRecord>> ListAdmins(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<AdminRecord>>([.. Admins.Values.OrderBy(a => a.Email, StringComparer.Ordinal)]);

    public Task<bool> IsPhoneBlocked(string phone, CancellationToken cancellationToken)
    {
        Step(nameof(IsPhoneBlocked));
        return Task.FromResult(Blocked.Contains(phone));
    }

    public Task<IReadOnlyList<string>> ListRoles(CancellationToken cancellationToken)
    {
        Step(nameof(ListRoles));
        return Task.FromResult<IReadOnlyList<string>>([.. Grants.Keys.Order(StringComparer.Ordinal)]);
    }

    public Task<IReadOnlyDictionary<string, Grants>> AllGrants(CancellationToken cancellationToken)
    {
        Step(nameof(AllGrants));
        return Task.FromResult<IReadOnlyDictionary<string, Grants>>(Grants.ToDictionary());
    }

    public Task<(IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens)> Catalogue(CancellationToken cancellationToken)
    {
        Step(nameof(Catalogue));
        return Task.FromResult((AllPermissions, AllScreens));
    }

    public Task CreateAccount(AccountRecord account, CancellationToken cancellationToken)
    {
        Step(nameof(CreateAccount));
        if (account is AdminRecord admin)
        {
            Admins[admin.Id] = admin;
        }
        else
        {
            Accounts[account.Id] = account with { Roles = [] };
        }
        return Task.CompletedTask;
    }

    public Task GrantRole(Guid accountId, string role, CancellationToken cancellationToken)
    {
        Step(nameof(GrantRole));
        Accounts[accountId] = Accounts[accountId] with { Roles = [.. Accounts[accountId].Roles.Append(role).Distinct().Order(StringComparer.Ordinal)] };
        return Task.CompletedTask;
    }

    public Task SetRoles(Guid accountId, IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        Step(nameof(SetRoles));
        if (Admins.TryGetValue(accountId, out var admin))
        {
            Admins[accountId] = admin with { Roles = [.. roles] };
        }
        else
        {
            Accounts[accountId] = Accounts[accountId] with { Roles = [.. roles] };
        }
        return Task.CompletedTask;
    }

    public Task UpdateStatus(Guid accountId, string status, CancellationToken cancellationToken)
    {
        Step(nameof(UpdateStatus));
        if (Admins.TryGetValue(accountId, out var admin))
        {
            Admins[accountId] = admin with { Status = status };
        }
        else
        {
            Accounts[accountId] = Accounts[accountId] with { Status = status };
        }
        return Task.CompletedTask;
    }

    public Task BlockPhone(string phone, string reason, CancellationToken cancellationToken)
    {
        Step(nameof(BlockPhone));
        Blocked.Add(phone);
        return Task.CompletedTask;
    }

    public Task UnblockPhone(string phone, CancellationToken cancellationToken)
    {
        Step(nameof(UnblockPhone));
        Blocked.Remove(phone);
        return Task.CompletedTask;
    }

    public Task AnonymiseAccount(Guid accountId, CancellationToken cancellationToken)
    {
        Step(nameof(AnonymiseAccount));
        Accounts[accountId] = Accounts[accountId] with { Phone = string.Empty, Email = string.Empty, Name = string.Empty, DeletedAt = DateTimeOffset.UtcNow };
        return Task.CompletedTask;
    }

    public Task CreateAdminCredentials(Guid accountId, string passwordHash, CancellationToken cancellationToken)
    {
        Step(nameof(CreateAdminCredentials));
        return Task.CompletedTask;
    }

    public Task SaveAdmin(AdminRecord admin, CancellationToken cancellationToken)
    {
        Step(nameof(SaveAdmin));
        Admins[admin.Id] = admin;
        return Task.CompletedTask;
    }

    public Task ReplaceRole(RoleDefinitionRecord role, CancellationToken cancellationToken)
    {
        Step(nameof(ReplaceRole));
        Grants[role.Role] = new(role.Permissions, role.Screens);
        return Task.CompletedTask;
    }

    public Task Publish(Guid aggregateId, IDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        Step(nameof(Publish));
        Events.Add(domainEvent);
        return Task.CompletedTask;
    }
}

public sealed class FakeCodes : Faulty, ICodeStore
{
    public Dictionary<string, StoredCode> Codes { get; } = [];

    public Task Save(string purpose, string phone, StoredCode code)
    {
        Step(nameof(Save));
        Codes[$"{purpose}:{phone}"] = code;
        return Task.CompletedTask;
    }

    public Task<StoredCode> Get(string purpose, string phone)
    {
        Step(nameof(Get));
        return Task.FromResult(Codes.GetValueOrDefault($"{purpose}:{phone}") ?? throw new DomainException(IdentityReasons.CodeExpired));
    }

    public Task IncrementAttempts(string purpose, string phone)
    {
        Step(nameof(IncrementAttempts));
        var key = $"{purpose}:{phone}";
        Codes[key] = Codes[key] with { Attempts = Codes[key].Attempts + 1 };
        return Task.CompletedTask;
    }

    public Task Delete(string purpose, string phone)
    {
        Step(nameof(Delete));
        Codes.Remove($"{purpose}:{phone}");
        return Task.CompletedTask;
    }
}

public sealed class FakeThrottle : Faulty, ISendThrottle
{
    public string? BlockedIp { get; set; }

    public Task<TimeSpan> RetryAfter(string phone, string? clientIp)
    {
        Step(nameof(RetryAfter));
        return Task.FromResult(clientIp is not null && clientIp == BlockedIp ? TimeSpan.FromSeconds(42) : TimeSpan.Zero);
    }
}

public sealed class FakeSms : Faulty, ISmsSender
{
    public string Last { get; private set; } = string.Empty;

    public Task Send(string phone, string message, CancellationToken cancellationToken)
    {
        Step(nameof(Send));
        Last = message;
        return Task.CompletedTask;
    }
}

public sealed class FakeSessions : Faulty, ISessionStore
{
    public Dictionary<Guid, Family> Families { get; } = [];

    public Task Save(Family family, TimeSpan ttl)
    {
        Step(nameof(Save));
        Families[family.Id] = family;
        return Task.CompletedTask;
    }

    public Task<Family> Get(Guid familyId)
    {
        Step(nameof(Get));
        return Task.FromResult(Families.GetValueOrDefault(familyId) ?? throw new DomainException(IdentityReasons.RefreshInvalid));
    }

    public Task Delete(Family family)
    {
        Step(nameof(Delete));
        Families.Remove(family.Id);
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<Family>> ListForAccount(Guid accountId)
    {
        Step(nameof(ListForAccount));
        return Task.FromResult<IReadOnlyList<Family>>([.. Families.Values.Where(f => f.AccountId == accountId)]);
    }
}

public sealed class FakeChallenges : Faulty, IChallengeStore
{
    public Dictionary<Guid, Challenge> Challenges { get; } = [];

    public Task Save(Challenge challenge, TimeSpan ttl)
    {
        Step(nameof(Save));
        Challenges[challenge.Id] = challenge;
        return Task.CompletedTask;
    }

    public Task<Challenge> Get(Guid id) =>
        Task.FromResult(Challenges.GetValueOrDefault(id) ?? throw new DomainException(IdentityReasons.ChallengeExpired));

    public Task Delete(Guid id)
    {
        Step(nameof(Delete));
        Challenges.Remove(id);
        return Task.CompletedTask;
    }
}

public sealed class FakeTokens : Faulty, IAccessTokens
{
    public List<string> Denied { get; } = [];

    public Task<(string Token, AccessClaims Claims)> Sign(AccountRecord account, Guid sessionId)
    {
        Step(nameof(Sign));
        var claims = new AccessClaims { Subject = account.Id.ToString(), Roles = account.Roles, TokenId = Guid.NewGuid().ToString(), SessionId = sessionId.ToString(), Version = 0, ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(15) };
        return Task.FromResult(("token-" + claims.TokenId, claims));
    }

    public Task Revoke(string tokenId, DateTimeOffset expiresAt)
    {
        Step(nameof(Revoke));
        Denied.Add(tokenId);
        return Task.CompletedTask;
    }
}

public sealed class FakeRbac(FakeRepository repository) : Faulty, IRbacGrants
{
    public int Version { get; private set; }

    public Task<Grants> Of(IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        Step(nameof(Of));
        var grants = roles.Select(r => repository.Grants.GetValueOrDefault(r)).OfType<Grants>().ToList();
        return Task.FromResult(new Grants(
            [.. grants.SelectMany(g => g.Permissions).Distinct().Order(StringComparer.Ordinal)],
            [.. grants.SelectMany(g => g.Screens).Distinct().Order(StringComparer.Ordinal)]));
    }

    public Task BumpVersion()
    {
        Step(nameof(BumpVersion));
        Version++;
        return Task.CompletedTask;
    }
}

public sealed class FakeLevels : Faulty, ILevelReader
{
    public int Level { get; set; }

    public Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken)
    {
        Step(nameof(GetLevel));
        return Task.FromResult(Level);
    }
}
