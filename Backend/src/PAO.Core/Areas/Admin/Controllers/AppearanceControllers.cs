using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Admin.Features.Appearance.Commands;
using PAO.Core.Areas.Admin.Features.Appearance.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Controllers;

/// <summary>The artwork slots on the admin Appearance page (ADR-0040).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/artwork")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class ArtworkController(IMediator mediator) : ControllerBase
{
    /// <summary>listArtwork.</summary>
    [HttpGet]
    [Admin(Permission = "settings:read")]
    public Task<ArtworkSlotList> List() => mediator.Send(new ListArtwork(), HttpContext.RequestAborted);

    /// <summary>uploadArtwork.</summary>
    [HttpPut("{slotKey}")]
    [Admin(Permission = "settings:manage")]
    public Task<ArtworkSlotView> Upload(string slotKey, [FromBody] ArtworkUpload body) =>
        mediator.Send(new UploadArtwork(slotKey, body, HttpContext.Caller().AccountId), HttpContext.RequestAborted);

    /// <summary>resetArtwork.</summary>
    [HttpDelete("{slotKey}")]
    [Admin(Permission = "settings:manage")]
    public Task<ArtworkSlotView> Reset(string slotKey) =>
        mediator.Send(new ResetArtwork(slotKey, HttpContext.Caller().AccountId), HttpContext.RequestAborted);
}

/// <summary>What the apps show without a release: tagline and artwork, with an ETag.</summary>
[ApiController]
[Area("Admin")]
[Route("v1/app-config")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class AppConfigController(IMediator mediator) : ControllerBase
{
    /// <summary>getAppConfig; answers 304 when the app's copy is current.</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> Get([FromQuery] string app)
    {
        var config = await mediator.Send(new GetAppConfig(app), HttpContext.RequestAborted);
        var tag = ETag(config);
        Response.Headers.ETag = tag;
        // Revalidate every time: a change must show on the next launch, and a 304 costs little.
        Response.Headers.CacheControl = "no-cache";
        return Request.Headers.IfNoneMatch == tag ? StatusCode(304) : Ok(config);
    }

    /// <summary>A strong ETag over the config's JSON.</summary>
    public static string ETag(AppConfigView config) =>
        $"\"{Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(config, JsonSerializerOptions.Web))))[..32]}\"";
}
