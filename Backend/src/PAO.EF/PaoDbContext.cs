using Microsoft.EntityFrameworkCore;
using PAO.EF.Conventions;
using PAO.EF.Identity;

namespace PAO.EF;

/// <summary>
/// The one DbContext over every area's schema. It maps the tables the SQL scripts in
/// "DB Changes" create; EF never creates or migrates schema (ADR-0034).
/// </summary>
public sealed class PaoDbContext(DbContextOptions<PaoDbContext> options) : DbContext(options)
{
    /// <summary>Roles and whether they belong to the admin console.</summary>
    public DbSet<Role> Roles => Set<Role>();

    /// <summary>Permission names (`resource:action`).</summary>
    public DbSet<Permission> Permissions => Set<Permission>();

    /// <summary>Which role grants which permission (02-architecture §6).</summary>
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();

    /// <summary>App screens the screen permissions refer to.</summary>
    public DbSet<Screen> Screens => Set<Screen>();

    /// <summary>Which role may open which screen.</summary>
    public DbSet<RoleScreen> RoleScreens => Set<RoleScreen>();

    /// <inheritdoc />
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(PaoDbContext).Assembly);
        SnakeCaseNames.Apply(modelBuilder);
    }
}
