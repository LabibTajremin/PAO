using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Identity.Features.Logout.Commands;
using PAO.Core.Areas.Identity.Features.RefreshToken.Commands;
using PAO.Core.Areas.Identity.Features.RequestOtp.Commands;
using PAO.Core.Areas.Identity.Features.VerifyOtp.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Controllers;

/// <summary>Phone sign-in, token refresh and sign-out (C-01, P-01).</summary>
[Area("Identity")]
[Route("v1/auth")]
[ErrorMap(typeof(IdentityErrorMap))]
public sealed class AuthController(IMediator mediator) : ControllerBase
{
    /// <summary>The admin web app's refresh cookie.</summary>
    public const string RefreshCookie = "pao_refresh";

    /// <summary>requestOtp: sends a sign-in or deletion code.</summary>
    [HttpPost("otp/request")]
    [AllowAnonymous]
    public async Task<IActionResult> RequestOtp([FromBody] OtpRequestBody body) =>
        StatusCode(202, await mediator.Send(new RequestOtpCommand(body.Phone, body.Purpose ?? CodePurpose.Login, HttpContext.Edge().ClientIp)));

    /// <summary>verifyOtp: signs in, creating the account on first use.</summary>
    [HttpPost("otp/verify")]
    [AllowAnonymous]
    public Task<TokenPairView> VerifyOtp([FromBody] OtpVerifyBody body) =>
        mediator.Send(new VerifyOtpCommand(body.Phone, body.Code, body.App));

    /// <summary>refreshToken: the body's token, else the admin cookie, which is then rotated.</summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<TokenPairView> Refresh([FromBody] RefreshBody body)
    {
        var cookie = body.RefreshToken is null ? Request.Cookies[RefreshCookie] : null;
        var session = await mediator.Send(new RefreshTokenCommand(body.RefreshToken ?? cookie ?? string.Empty, cookie is not null));
        if (cookie is not null)
        {
            Response.Headers.SetCookie = Cookie(session.RefreshToken, IdentityRules.RefreshTtl);
        }
        return session.View;
    }

    /// <summary>logout: this device, or every device; clears the admin cookie.</summary>
    [HttpPost("logout")]
    [AllUserType]
    public async Task<IActionResult> Logout([FromBody] LogoutBody body)
    {
        var me = HttpContext.Caller();
        var caller = new Caller(me.AccountId, Guid.Parse(me.SessionId), me.TokenId, me.ExpiresAt);
        await mediator.Send(new LogoutCommand(caller, body.AllDevices == true));
        if (Request.Cookies.ContainsKey(RefreshCookie))
        {
            Response.Headers.SetCookie = Cookie(string.Empty, TimeSpan.Zero);
        }
        return NoContent();
    }

    /// <summary>The admin refresh cookie; a zero `maxAge` clears it.</summary>
    public static string Cookie(string token, TimeSpan maxAge) =>
        $"{RefreshCookie}={token}; Path=/v1/auth; Max-Age={(long)maxAge.TotalSeconds}; HttpOnly; Secure; SameSite=Strict";
}
