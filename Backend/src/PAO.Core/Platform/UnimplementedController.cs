using Microsoft.AspNetCore.Mvc;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;

namespace PAO.Core.Platform;

/// <summary>
/// Answers 501 NOT_IMPLEMENTED for spec operations no area serves yet, after the same
/// authentication, permission, rate-limit and validation checks a real route gets. Routes
/// of the areas always win over this catch-all.
/// </summary>
[ApiController]
[PermissionFromSpec]
public sealed class UnimplementedController : ControllerBase
{
    /// <summary>Throws NOT_IMPLEMENTED.</summary>
    [Route("{**path}", Order = int.MaxValue)]
    [AcceptVerbs("GET", "POST", "PUT", "PATCH", "DELETE")]
    public IActionResult NotImplemented() => throw ApiErrors.NotImplemented;
}
