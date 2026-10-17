namespace PAO.EF.Identity;

/// <summary>A row of `identity.roles`.</summary>
public sealed class Role
{
    public required string Name { get; set; }
    public required string Description { get; set; }
    public bool IsAdmin { get; set; }
}

/// <summary>A row of `identity.permissions`.</summary>
public sealed class Permission
{
    public required string Name { get; set; }
    public required string Description { get; set; }
}

/// <summary>A row of `identity.role_permissions`.</summary>
public sealed class RolePermission
{
    public required string Role { get; set; }
    public required string Permission { get; set; }
}

/// <summary>A row of `identity.screens`.</summary>
public sealed class Screen
{
    public required string Id { get; set; }
    public required string App { get; set; }
    public required string Name { get; set; }
}

/// <summary>A row of `identity.role_screens`.</summary>
public sealed class RoleScreen
{
    public required string Role { get; set; }
    public required string ScreenId { get; set; }
}
