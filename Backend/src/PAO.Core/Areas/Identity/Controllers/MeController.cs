using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Identity.Features.DeleteMe.Commands;
using PAO.Core.Areas.Identity.Features.GetMe.Queries;
using PAO.Core.Areas.Identity.Features.GetMyPermissions.Queries;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Controllers;

/// <summary>The signed-in account: profile, grants and deletion.</summary>
[Area("Identity")]
[Route("v1/me")]
[ErrorMap(typeof(IdentityErrorMap))]
public sealed class MeController(IMediator mediator) : ControllerBase
{
    /// <summary>getMe.</summary>
    [HttpGet]
    [AllUserType]
    public Task<AccountView> Get() => mediator.Send(new GetMeQuery(HttpContext.Caller().AccountId));

    /// <summary>getMyPermissions.</summary>
    [HttpGet("permissions")]
    [AllUserType]
    public Task<MyPermissionsView> Permissions() => mediator.Send(new GetMyPermissionsQuery(HttpContext.Caller().AccountId));

    /// <summary>deleteMe: erases the account after a fresh `delete_account` code.</summary>
    [HttpDelete]
    [AllUserType]
    public async Task<IActionResult> Delete([FromBody] DeleteAccountBody body)
    {
        await mediator.Send(new DeleteMeCommand(HttpContext.Caller().AccountId, body.Code));
        return NoContent();
    }
}
