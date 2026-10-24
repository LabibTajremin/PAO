namespace PAO.EF.Identity;

/// <summary>A row of `identity.roles`.</summary>
public sealed class Role
{
    /// <summary>The name.</summary>
    public required string Name { get; set; }
    /// <summary>The description.</summary>
    public required string Description { get; set; }
    /// <summary>Whether admin.</summary>
    public bool IsAdmin { get; set; }
}

/// <summary>A row of `identity.permissions`.</summary>
public sealed class Permission
{
    /// <summary>The name.</summary>
    public required string Name { get; set; }
    /// <summary>The description.</summary>
    public required string Description { get; set; }
}

/// <summary>A row of `identity.role_permissions`.</summary>
public sealed class RolePermission
{
    /// <summary>The role.</summary>
    public required string Role { get; set; }
    /// <summary>The permission.</summary>
    public required string Permission { get; set; }
}

/// <summary>A row of `identity.screens`.</summary>
public sealed class Screen
{
    /// <summary>The id.</summary>
    public required string Id { get; set; }
    /// <summary>The app.</summary>
    public required string App { get; set; }
    /// <summary>The name.</summary>
    public required string Name { get; set; }
}

/// <summary>A row of `identity.role_screens`.</summary>
public sealed class RoleScreen
{
    /// <summary>The role.</summary>
    public required string Role { get; set; }
    /// <summary>The screen id.</summary>
    public required string ScreenId { get; set; }
}
