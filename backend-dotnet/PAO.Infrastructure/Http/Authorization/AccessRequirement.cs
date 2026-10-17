using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Controllers;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.Infrastructure.Http.Authorization;

/// <summary>What a request must prove before the action runs.</summary>
public enum AccessKind
{
    /// <summary>The action declares nothing: denied (deny by default).</summary>
    Undeclared,
    Public,
    Authenticated,
    Permission,
    AnyAdminRole,
}

/// <summary>The requirement of one action, read from its attributes (method over class).</summary>
public sealed record AccessRequirement(AccessKind Kind, string? Permission = null)
{
    /// <summary>x-permission `public`: no token.</summary>
    public const string PublicPermission = "public";

    /// <summary>x-permission `authenticated`: any signed-in account.</summary>
    public const string AuthenticatedPermission = "authenticated";

    /// <summary>Reads the requirement of `action`, resolving the catch-all from the matched `operation`.</summary>
    public static AccessRequirement For(ControllerActionDescriptor action, MatchedOperation? operation)
    {
        var fromMethod = Declared(action.MethodInfo);
        var declared = fromMethod ?? Declared(action.ControllerTypeInfo);
        return declared switch
        {
            AllowAnonymousAttribute => new(AccessKind.Public),
            PermissionFromSpecAttribute => FromSpec(operation?.Operation.Permission),
            AdminAttribute { Permission: null } => new(AccessKind.AnyAdminRole),
            AccessAttribute { Permission: null } => new(AccessKind.Authenticated),
            AccessAttribute access => new(AccessKind.Permission, access.Permission),
            _ => new(AccessKind.Undeclared),
        };
    }

    /// <summary>The requirement an `x-permission` value states.</summary>
    public static AccessRequirement FromSpec(string? permission) => permission switch
    {
        null => new(AccessKind.Undeclared),
        PublicPermission => new(AccessKind.Public),
        AuthenticatedPermission => new(AccessKind.Authenticated),
        _ => new(AccessKind.Permission, permission),
    };

    /// <summary>The access attribute (or AllowAnonymous / PermissionFromSpec) on `member`, if any.</summary>
    public static Attribute? Declared(MemberInfo member) =>
        member.GetCustomAttributes(inherit: true).OfType<Attribute>()
            .FirstOrDefault(a => a is AllowAnonymousAttribute or AccessAttribute or PermissionFromSpecAttribute);
}
