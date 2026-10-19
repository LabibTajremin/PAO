using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Merchant.Features.Presence.Commands;
using PAO.Core.Areas.Merchant.Features.Profile.Commands;
using PAO.Core.Areas.Merchant.Features.Profile.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Controllers;

/// <summary>Merchant failures as API errors, with the Go and NestJS codes and messages.</summary>
public sealed class MerchantErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [MerchantErrors.NotFound] = ApiErrors.NotFound,
        [MerchantReasons.Invalid] = new(422, "VALIDATION_FAILED", "Check the details and try again."),
        [MerchantReasons.TooYoung] = new(422, "AGE_REQUIREMENT", "Providers must be at least 18 years old."),
        [MerchantReasons.UnknownService] = new(422, "SERVICE_UNAVAILABLE", "One of these services is not offered."),
        [MerchantReasons.InvalidPhoto] = new(422, "UPLOAD_INVALID", "Upload the photo again."),
        [MerchantReasons.CodeRejected] = new(422, "OTP_INVALID", "The code is wrong or expired."),
        [MerchantReasons.CodeRateLimited] = new(429, "RATE_LIMITED", "Too many codes. Try again later."),
        [MerchantReasons.ContactUnproven] = new(409, "EMERGENCY_CONTACT_MISSING", "Add the emergency contact first."),
        [MerchantReasons.NotVerified] = new(403, "NOT_VERIFIED", "You can go online after verification."),
        [MerchantReasons.NoServiceArea] = new(409, "SERVICE_AREA_MISSING", "Choose your services and area first."),
        [MerchantReasons.Offline] = new(409, "OFFLINE", "Go online first."),
    };
}

/// <summary>The merchant's own profile (M28).</summary>
[ApiController]
[Area("Merchant")]
[Route("v1/provider/profile")]
[ErrorMap(typeof(MerchantErrorMap))]
[Merchant(Permission = "provider:manage:own")]
public sealed class MerchantProfileController(IMediator mediator) : ControllerBase
{
    /// <summary>getProviderProfile.</summary>
    [HttpGet]
    public Task<MerchantProfileView> Get() => mediator.Send(new GetMerchantProfile(HttpContext.Caller().AccountId), HttpContext.RequestAborted);

    /// <summary>updateProviderProfile.</summary>
    [HttpPut]
    public Task<MerchantProfileView> Update([FromBody] MerchantProfileInput body) =>
        mediator.Send(new UpdateMerchantProfile(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);
}

/// <summary>Going online, staying online and going offline (PRD §6.1).</summary>
[ApiController]
[Area("Merchant")]
[Route("v1/provider/presence")]
[ErrorMap(typeof(MerchantErrorMap))]
[Merchant(Permission = "provider:manage:own")]
public sealed class PresenceController(IMediator mediator) : ControllerBase
{
    /// <summary>goOnline.</summary>
    [HttpPost("online")]
    public Task<PresenceStateView> Online([FromBody] HeartbeatInput body) =>
        mediator.Send(new GoOnline(HttpContext.Caller().AccountId, body.Location), HttpContext.RequestAborted);

    /// <summary>sendHeartbeat.</summary>
    [HttpPost("heartbeat")]
    public Task<PresenceStateView> Heartbeat([FromBody] HeartbeatInput body) =>
        mediator.Send(new SendHeartbeat(HttpContext.Caller().AccountId, body.Location), HttpContext.RequestAborted);

    /// <summary>goOffline.</summary>
    [HttpPost("offline")]
    public Task<PresenceStateView> Offline() => mediator.Send(new GoOffline(HttpContext.Caller().AccountId), HttpContext.RequestAborted);
}

/// <summary>A merchant as customers see them (C11).</summary>
[ApiController]
[Area("Merchant")]
[Route("v1/customer/providers")]
[ErrorMap(typeof(MerchantErrorMap))]
public sealed class PublicProfileController(IMediator mediator) : ControllerBase
{
    /// <summary>getProviderPublicProfile.</summary>
    [HttpGet("{providerId}")]
    [Customer(Permission = "provider:browse")]
    public Task<MerchantPublicProfileView> Get(Guid providerId) =>
        mediator.Send(new GetMerchantPublicProfile(HttpContext.Caller().AccountId, providerId), HttpContext.RequestAborted);
}
