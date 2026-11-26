using Microsoft.EntityFrameworkCore;
using PAO.EF;

namespace PAO.Infrastructure.Rbac;

/// <summary>What one role, or a set of roles, allows.</summary>
public sealed record Grants(IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens);

/// <summary>Loads roles' grants from the system of record.</summary>
public interface IRbacSource
{
    /// <summary>Returns the grants of every role in `roles` (empty grants for unknown roles), in one round trip per table.</summary>
    Task<IReadOnlyDictionary<string, Grants>> LoadGrants(IReadOnlyCollection<string> roles, CancellationToken cancellationToken);
}

/// <summary>Reads grants from `identity.role_permissions` and `identity.role_screens` through EF.</summary>
public sealed class EfRbacSource(IDbContextFactory<PaoDbContext> contexts) : IRbacSource
{
    /// <inheritdoc />
    public async Task<IReadOnlyDictionary<string, Grants>> LoadGrants(IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        await using var db = await contexts.CreateDbContextAsync(cancellationToken);
        var permissions = await db.RolePermissions
            .Where(rp => roles.Contains(rp.Role))
            .Select(rp => new { rp.Role, Value = rp.Permission })
            .ToListAsync(cancellationToken);
        var screens = await db.RoleScreens
            .Where(rs => roles.Contains(rs.Role))
            .Select(rs => new { rs.Role, Value = rs.ScreenId })
            .ToListAsync(cancellationToken);
        return roles.ToDictionary(
            role => role,
            role => new Grants(
                [.. permissions.Where(p => p.Role == role).Select(p => p.Value).Order(StringComparer.Ordinal)],
                [.. screens.Where(s => s.Role == role).Select(s => s.Value).Order(StringComparer.Ordinal)]));
    }
}
