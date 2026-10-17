using System.Reflection;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;
using PAO.Core;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.UnitTests.Architecture;

/// <summary>Checks controller authorisation attributes: present on every action, and matching the spec.</summary>
public static partial class AuthorizationAudit
{
    private static readonly HashSet<string> AdminRoles = ["verifier", "catalog_manager", "support_agent", "super_admin"];

    /// <summary>Actions with no access attribute, as `Controller.Action`.</summary>
    public static IEnumerable<string> Unmarked(IEnumerable<Type> controllers) =>
        Actions(controllers).Where(a => AccessRequirement.Declared(a) is null && AccessRequirement.Declared(a.DeclaringType!) is null)
            .Select(a => $"{a.DeclaringType!.Name}.{a.Name}");

    /// <summary>Actions whose attribute disagrees with their operation's x-permission and security.</summary>
    public static IEnumerable<string> Mismatched(IEnumerable<Type> controllers, SpecRoutes routes, IReadOnlyDictionary<string, HashSet<string>> holders)
    {
        foreach (var action in Actions(controllers))
        {
            var declared = AccessRequirement.Declared(action) ?? AccessRequirement.Declared(action.DeclaringType!);
            if (declared is PermissionFromSpecAttribute)
            {
                continue;
            }
            foreach (var (method, path) in Routes(action))
            {
                var op = routes.Match(method, path).Match?.Operation;
                if (op is null || Expected(op, holders) != Describe(declared))
                {
                    yield return $"{method} {path}: {Describe(declared)} vs {(op is null ? "no operation" : Expected(op, holders))}";
                }
            }
        }
    }

    /// <summary>Role → permissions from the RBAC seed script.</summary>
    public static IReadOnlyDictionary<string, HashSet<string>> Holders(string seedSql)
    {
        var holders = new Dictionary<string, HashSet<string>>();
        foreach (Match m in Grant().Matches(seedSql))
        {
            if (!holders.TryGetValue(m.Groups[2].Value, out var roles))
            {
                holders[m.Groups[2].Value] = roles = [];
            }
            roles.Add(m.Groups[1].Value);
        }
        return holders;
    }

    private static string Expected(OperationInfo op, IReadOnlyDictionary<string, HashSet<string>> holders)
    {
        if (op.Permission == AccessRequirement.PublicPermission)
        {
            return op.Public ? "AllowAnonymous" : "public without security: []";
        }
        if (op.Permission == AccessRequirement.AuthenticatedPermission)
        {
            return "AllUserType";
        }
        var roles = holders.GetValueOrDefault(op.Permission!, []).Where(r => r != "super_admin").ToHashSet();
        var audience = roles.All(AdminRoles.Contains) ? "Admin"
            : roles.SetEquals(["customer"]) ? "Customer"
            : roles.SetEquals(["provider"]) ? "Merchant" : "AllUserType";
        return $"{audience}({op.Permission})";
    }

    private static string Describe(Attribute? declared) => declared switch
    {
        AllowAnonymousAttribute => "AllowAnonymous",
        AccessAttribute { Permission: null } a => a.Audience == Audience.Admin ? "Admin" : "AllUserType",
        AccessAttribute a => $"{(a.Audience == Audience.AllUserTypes ? "AllUserType" : a.Audience.ToString())}({a.Permission})",
        _ => "none",
    };

    private static IEnumerable<MethodInfo> Actions(IEnumerable<Type> controllers) =>
        controllers.SelectMany(c => c.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly));

    private static IEnumerable<(string Method, string Path)> Routes(MethodInfo action)
    {
        var prefix = action.DeclaringType!.GetCustomAttribute<RouteAttribute>()?.Template ?? string.Empty;
        foreach (var http in action.GetCustomAttributes<HttpMethodAttribute>())
        {
            var path = "/" + string.Join('/', new[] { prefix, http.Template ?? string.Empty }.Where(p => p.Length > 0)).TrimStart('/');
            foreach (var method in http.HttpMethods)
            {
                yield return (method, Placeholder().Replace(path, "x"));
            }
        }
    }

    [GeneratedRegex(@"\('(\w+)', '([\w:]+)'\)")]
    private static partial Regex Grant();

    [GeneratedRegex(@"\{[^}]+\}")]
    private static partial Regex Placeholder();
}

[Trait("Category", "Gate")]
public sealed class AuthorizationTests
{
    private static readonly PaoPaths Paths = PaoPaths.Resolve(AppContext.BaseDirectory, null);
    private static readonly SpecRoutes Routes = new(SpecDocument.Load(Paths.Spec));
    private static readonly IReadOnlyDictionary<string, HashSet<string>> Holders =
        AuthorizationAudit.Holders(File.ReadAllText(Path.Combine(Paths.Migrations, "identity", "0002_seed_rbac.sql")));

    [Fact]
    public void Every_controller_action_carries_an_authorisation_attribute()
    {
        Assert.Empty(AuthorizationAudit.Unmarked(ArchitectureTests.Controllers(typeof(ApiHost).Assembly)));
    }

    [Fact]
    public void Every_attribute_matches_the_spec_permission_and_security()
    {
        Assert.Empty(AuthorizationAudit.Mismatched(ArchitectureTests.Controllers(typeof(ApiHost).Assembly), Routes, Holders));
    }

    [Fact]
    public void The_audit_catches_missing_and_wrong_attributes()
    {
        Assert.Equal(["SampleController.Forgotten"], AuthorizationAudit.Unmarked([typeof(SampleController)]));
        var mismatched = AuthorizationAudit.Mismatched([typeof(SampleController)], Routes, Holders).ToList();
        Assert.Contains("POST /v1/auth/otp/request: Admin vs AllowAnonymous", mismatched);
        Assert.Contains("GET /v1/nowhere: AllowAnonymous vs no operation", mismatched);
        Assert.Equal(4, mismatched.Count);
        Assert.Empty(AuthorizationAudit.Mismatched([typeof(MatchingController)], Routes, Holders));
    }
}

[Route("v1")]
public sealed class SampleController : ControllerBase
{
    [HttpPost("auth/otp/request")]
    [Admin]
    public void WrongAudience() { }

    [HttpGet("nowhere")]
    [AllowAnonymous]
    public void NotInSpec() { }

    [HttpPost("customer/bookings")]
    [Merchant(Permission = "booking:create")]
    public void WrongRole() { }

    [HttpGet("bookings")]
    public void Forgotten() { }
}

public sealed class MatchingController : ControllerBase
{
    [HttpPost("/v1/auth/otp/request")]
    [AllowAnonymous]
    public void Otp() { }

    [HttpPost("/v1/customer/bookings")]
    [Customer(Permission = "booking:create")]
    public void Book() { }

    [HttpGet("/v1/me/permissions")]
    [AllUserType]
    public void Me() { }

    [HttpGet("/v1/admin/audit")]
    [Admin(Permission = "audit:read")]
    public void Audit() { }
}
