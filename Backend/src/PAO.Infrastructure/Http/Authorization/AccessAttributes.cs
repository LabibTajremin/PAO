namespace PAO.Infrastructure.Http.Authorization;

/// <summary>Who an operation is for; the spec test checks it against each `x-permission`.</summary>
public enum Audience
{
    /// <summary>Admin.</summary>
    Admin,
    /// <summary>Customer.</summary>
    Customer,
    /// <summary>Merchant.</summary>
    Merchant,
    /// <summary>All user types.</summary>
    AllUserTypes,
}

/// <summary>
/// The authorisation attribute every controller action carries (deny by default,
/// 02-architecture §7). The audience names who the operation is for; the permission is
/// what RBAC enforces, so super_admin keeps the grants it has in the identity tables, as
/// it did in earlier releases.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public abstract class AccessAttribute : Attribute
{
    /// <summary>Who the operation is for.</summary>
    public abstract Audience Audience { get; }

    /// <summary>The `resource:action` permission the caller's roles must grant; the spec's `x-permission`.</summary>
    public string? Permission { get; init; }
}

/// <summary>Admin console operations: `[Admin(Permission = "catalog:manage")]`; without a permission, any admin role.</summary>
public sealed class AdminAttribute : AccessAttribute
{
    /// <inheritdoc />
    public override Audience Audience => Audience.Admin;
}

/// <summary>Customer app operations: `[Customer(Permission = "booking:create")]`.</summary>
public sealed class CustomerAttribute : AccessAttribute
{
    /// <inheritdoc />
    public override Audience Audience => Audience.Customer;
}

/// <summary>Partner app operations; "Merchant" is the owner's name for the provider role.</summary>
public sealed class MerchantAttribute : AccessAttribute
{
    /// <inheritdoc />
    public override Audience Audience => Audience.Merchant;
}

/// <summary>Operations for any signed-in account; with a permission, only accounts whose roles grant it.</summary>
public sealed class AllUserTypeAttribute : AccessAttribute
{
    /// <inheritdoc />
    public override Audience Audience => Audience.AllUserTypes;
}

/// <summary>
/// Takes the requirement from the matched operation's `x-permission`; only for the catch-all
/// that answers operations no area serves yet.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class PermissionFromSpecAttribute : Attribute;
