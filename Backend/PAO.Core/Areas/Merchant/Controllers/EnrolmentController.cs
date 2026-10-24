using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Merchant.Features.Enrolment.Commands;
using PAO.Core.Areas.Merchant.Features.Enrolment.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Controllers;

/// <summary>The profile steps of the enrolment wizard (M05–M13); the document steps belong to Verification.</summary>
[ApiController]
[Area("Merchant")]
[Route("v1/provider/enrolment")]
[ErrorMap(typeof(MerchantErrorMap))]
[Merchant(Permission = "provider:manage:own")]
public sealed class EnrolmentController(IMediator mediator) : ControllerBase
{
    /// <summary>getEnrolment.</summary>
    [HttpGet]
    public Task<EnrolmentStatus> Get() => mediator.Send(new GetEnrolment(Me), HttpContext.RequestAborted);

    /// <summary>savePersonalStep.</summary>
    [HttpPut("personal")]
    public Task<EnrolmentStatus> Personal([FromBody] PersonalInfoInput body) =>
        mediator.Send(new SavePersonalStep(Me, body), HttpContext.RequestAborted);

    /// <summary>saveServicesStep.</summary>
    [HttpPut("services")]
    public Task<EnrolmentStatus> Services([FromBody] ServicesInput body) =>
        mediator.Send(new SaveServicesStep(Me, body), HttpContext.RequestAborted);

    /// <summary>saveAreaStep.</summary>
    [HttpPut("area")]
    public Task<EnrolmentStatus> Area([FromBody] ServiceAreaInput body) =>
        mediator.Send(new SaveAreaStep(Me, body), HttpContext.RequestAborted);

    /// <summary>saveEmergencyContactStep.</summary>
    [HttpPut("emergency-contact")]
    public Task<EnrolmentStatus> EmergencyContact([FromBody] EmergencyContactInput body) =>
        mediator.Send(new SaveEmergencyContactStep(Me, body), HttpContext.RequestAborted);

    /// <summary>verifyEmergencyContact.</summary>
    [HttpPost("emergency-contact/verify")]
    public Task<EnrolmentStatus> VerifyEmergencyContact([FromBody] EmergencyContactVerifyInput body) =>
        mediator.Send(new VerifyEmergencyContact(Me, body.Code), HttpContext.RequestAborted);

    /// <summary>saveCodeOfConductStep.</summary>
    [HttpPut("code-of-conduct")]
    public Task<EnrolmentStatus> CodeOfConduct([FromBody] CodeOfConductInput body) =>
        mediator.Send(new SaveCodeOfConductStep(Me, body), HttpContext.RequestAborted);

    private Guid Me => HttpContext.Caller().AccountId;
}
