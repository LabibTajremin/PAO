using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Identity.Features.AdminLogin.Commands;
using PAO.Core.Areas.Identity.Features.AdminVerifyTotp.Commands;
using PAO.Core.Areas.Identity.Features.ChangeAdminPassword.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Controllers;

/// <summary>Admin email + password + TOTP sign-in and password change (A-01).</summary>
[Area("Identity")]
[Route("v1/auth/admin")]
[ErrorMap(typeof(IdentityErrorMap))]
public sealed class AdminAuthController(IMediator mediator) : ControllerBase
{
    /// <summary>adminLogin: step 1.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public Task<AdminLoginChallengeView> Login([FromBody] AdminLoginBody body) =>
        mediator.Send(new AdminLoginRequest(body.Email, body.Password));

    /// <summary>adminVerifyTotp: step 2; the refresh token goes in the HttpOnly cookie.</summary>
    [HttpPost("totp")]
    [AllowAnonymous]
    public async Task<TokenPairView> VerifyTotp([FromBody] AdminTotpBody body)
    {
        var session = await mediator.Send(new AdminVerifyTotpCommand(body.ChallengeId, body.Code));
        Response.Headers.SetCookie = AuthController.Cookie(session.RefreshToken, IdentityRules.RefreshTtl);
        return session.View;
    }

    /// <summary>changeAdminPassword.</summary>
    [HttpPost("password")]
    [AllUserType]
    public async Task<IActionResult> ChangePassword([FromBody] AdminPasswordChangeBody body)
    {
        await mediator.Send(new ChangeAdminPasswordCommand(HttpContext.Caller().AccountId, body.CurrentPassword, body.NewPassword));
        return NoContent();
    }
}
