using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Identity;

/// <summary>Maps <see cref="Role"/> to `identity.roles`.</summary>
public sealed class RoleConfiguration : IEntityTypeConfiguration<Role>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Role> builder)
    {
        builder.ToTable("roles", Schemas.Identity);
        builder.HasKey(r => r.Name);
    }
}

/// <summary>Maps <see cref="Permission"/> to `identity.permissions`.</summary>
public sealed class PermissionConfiguration : IEntityTypeConfiguration<Permission>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Permission> builder)
    {
        builder.ToTable("permissions", Schemas.Identity);
        builder.HasKey(p => p.Name);
    }
}

/// <summary>Maps <see cref="RolePermission"/> to `identity.role_permissions`.</summary>
public sealed class RolePermissionConfiguration : IEntityTypeConfiguration<RolePermission>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<RolePermission> builder)
    {
        builder.ToTable("role_permissions", Schemas.Identity);
        builder.HasKey(rp => new { rp.Role, rp.Permission });
    }
}

/// <summary>Maps <see cref="Screen"/> to `identity.screens`.</summary>
public sealed class ScreenConfiguration : IEntityTypeConfiguration<Screen>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Screen> builder)
    {
        builder.ToTable("screens", Schemas.Identity);
        builder.HasKey(s => s.Id);
    }
}

/// <summary>Maps <see cref="RoleScreen"/> to `identity.role_screens`.</summary>
public sealed class RoleScreenConfiguration : IEntityTypeConfiguration<RoleScreen>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<RoleScreen> builder)
    {
        builder.ToTable("role_screens", Schemas.Identity);
        builder.HasKey(rs => new { rs.Role, rs.ScreenId });
    }
}
