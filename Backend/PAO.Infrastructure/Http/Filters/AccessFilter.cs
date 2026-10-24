using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Filters;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Identity;
using Serilog.Context;

namespace PAO.Infrastructure.Http.Filters;

/// <summary>
/// Authentication then authorisation, before rate limits and validation: a valid,
/// unrevoked bearer token unless the action is public, then the action's requirement
/// against the caller's roles (02-architecture §6). An action without an attribute is denied.
/// </summary>
public sealed class AccessFilter(TokenVerifier verifier, Denylist denylist, RbacChecker rbac) : IAsyncActionFilter
{
    /// <inheritdoc />
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var edge = context.HttpContext.Edge();
        var requirement = AccessRequirement.For((ControllerActionDescriptor)context.ActionDescriptor, edge.Operation);
        if (requirement.Kind == AccessKind.Public)
        {
            await next();
            return;
        }
        var principal = await Authenticate(context.HttpContext.Request.Headers.Authorization.ToString());
        edge.Principal = principal;
        context.HttpContext.User = principal.ToClaimsPrincipal();
        using (LogContext.PushProperty("user_id", principal.AccountId))
        {
            await Authorize(requirement, principal, context.HttpContext.RequestAborted);
            await next();
        }
    }

    private async Task<Principal> Authenticate(string authorization)
    {
        var token = authorization.StartsWith("Bearer ", StringComparison.Ordinal) ? authorization[7..] : string.Empty;
        if (token.Length == 0)
        {
            throw ApiErrors.Unauthenticated;
        }
        AccessClaims claims;
        try
        {
            claims = verifier.Verify(token);
        }
        catch (TokenExpiredException)
        {
            throw ApiErrors.TokenExpired;
        }
        catch (TokenInvalidException)
        {
            throw ApiErrors.Unauthenticated;
        }
        return await denylist.IsDenied(claims.TokenId) ? throw ApiErrors.Unauthenticated : Principal.From(claims);
    }

    private async Task Authorize(AccessRequirement requirement, Principal principal, CancellationToken cancellationToken)
    {
        var allowed = requirement.Kind switch
        {
            AccessKind.Authenticated => true,
            AccessKind.AnyAdminRole => principal.Roles.Any(Roles.Admin.Contains),
            AccessKind.Permission => await rbac.Has(principal.Roles, requirement.Permission!, cancellationToken),
            _ => false,
        };
        if (!allowed)
        {
            throw requirement.Permission is null
                ? ApiErrors.Forbidden
                : ApiErrors.Forbidden.WithDetails(new Dictionary<string, object?> { ["permission"] = requirement.Permission });
        }
    }
}

