using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Verification.Features.Enrolment.Commands;
using PAO.Core.Areas.Verification.Features.Level2.Commands;
using PAO.Core.Areas.Verification.Features.Level2.Queries;
using PAO.Core.Areas.Verification.Features.Review.Commands;
using PAO.Core.Areas.Verification.Features.Review.Queries;
using PAO.Core.Areas.Verification.Features.Status.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Controllers;

/// <summary>Verification failures as API errors, with the Go and NestJS codes and messages.</summary>
public sealed class VerificationErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [VerificationReasons.NotFound] = ApiErrors.NotFound,
        [VerificationReasons.Invalid] = new(422, "VALIDATION_FAILED", "Check the details and try again."),
        [VerificationReasons.BadDocument] = new(422, "UPLOAD_INVALID", "Upload the document again."),
        [VerificationReasons.ClearanceTooOld] = new(422, "CLEARANCE_TOO_OLD", "The police clearance must be issued within the last 12 months."),
        [VerificationReasons.NidBlocked] = new(403, "NID_BLOCKED", "This NID cannot be used to register."),
        [VerificationReasons.NotPending] = new(409, "ITEM_NOT_PENDING", "This item is not waiting for a decision."),
        [VerificationReasons.EnrolmentPending] = new(409, "ENROLMENT_INCOMPLETE", "Finish every required step first."),
        [VerificationReasons.NotEligible] = new(409, "LEVEL2_NOT_ELIGIBLE", "Level 2 needs a Level 1 provider."),
        [VerificationReasons.CoolingOff] = new(409, "LEVEL2_COOLING_OFF", "The provider must wait before retrying."),
        [VerificationReasons.SessionClosed] = new(409, "SESSION_CLOSED", "This session already has a result."),
    };
}

/// <summary>The document steps of the enrolment wizard (M08–M11) and submission.</summary>
[ApiController]
[Area("Verification")]
[Route("v1/provider/enrolment")]
[ErrorMap(typeof(VerificationErrorMap))]
public sealed class EnrolmentDocumentsController(IMediator mediator) : ControllerBase
{
    /// <summary>saveNid.</summary>
    [HttpPut("nid")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<EnrolmentStatusView> Nid([FromBody] NidInput body) =>
        mediator.Send(new SaveNid(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);

    /// <summary>saveSelfie.</summary>
    [HttpPut("selfie")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<EnrolmentStatusView> Selfie([FromBody] SelfieInput body) =>
        mediator.Send(new SaveSelfie(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);

    /// <summary>savePoliceClearance.</summary>
    [HttpPut("police-clearance")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<EnrolmentStatusView> PoliceClearance([FromBody] PoliceClearanceInput body) =>
        mediator.Send(new SavePoliceClearance(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);

    /// <summary>saveSkillProof.</summary>
    [HttpPut("skill-proof")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<EnrolmentStatusView> SkillProof([FromBody] SkillProofInput body) =>
        mediator.Send(new SaveSkillProof(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);

    /// <summary>submitEnrolment.</summary>
    [HttpPost("submit")]
    [Merchant(Permission = "verification:submit")]
    public Task<VerificationStatusView> Submit() =>
        mediator.Send(new SubmitEnrolment(HttpContext.Caller().AccountId), HttpContext.RequestAborted);
}

/// <summary>The merchant's verification screen (M14/P-03).</summary>
[ApiController]
[Area("Verification")]
[Route("v1/provider/verification")]
[ErrorMap(typeof(VerificationErrorMap))]
public sealed class VerificationStatusController(IMediator mediator) : ControllerBase
{
    /// <summary>getVerificationStatus.</summary>
    [HttpGet]
    [Merchant(Permission = "provider:manage:own")]
    public Task<VerificationStatusView> Get() =>
        mediator.Send(new GetVerificationStatus(HttpContext.Caller().AccountId), HttpContext.RequestAborted);
}

/// <summary>The review queue and per-item decisions (A-03, A06).</summary>
[ApiController]
[Area("Verification")]
[Route("v1/admin/verifications")]
[ErrorMap(typeof(VerificationErrorMap))]
[Admin(Permission = "verification:review")]
public sealed class VerificationReviewController(IMediator mediator) : ControllerBase
{
    /// <summary>listVerificationQueue.</summary>
    [HttpGet]
    public Task<VerificationQueueView> Queue([FromQuery] string? itemType, [FromQuery] Guid? serviceId, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListVerificationQueue(itemType, serviceId, cursor, limit), HttpContext.RequestAborted);

    /// <summary>getVerificationReview.</summary>
    [HttpGet("{providerId}")]
    public Task<VerificationReviewView> Get(Guid providerId) =>
        mediator.Send(new GetVerificationReview(providerId), HttpContext.RequestAborted);

    /// <summary>approveVerificationItem.</summary>
    [HttpPost("{providerId}/items/{itemType}/approve")]
    public Task<VerificationReviewView> Approve(Guid providerId, string itemType) =>
        mediator.Send(new DecideVerificationItem(providerId, itemType, HttpContext.Caller().AccountId, true, string.Empty), HttpContext.RequestAborted);

    /// <summary>rejectVerificationItem.</summary>
    [HttpPost("{providerId}/items/{itemType}/reject")]
    public Task<VerificationReviewView> Reject(Guid providerId, string itemType, [FromBody] RejectionInput body) =>
        mediator.Send(new DecideVerificationItem(providerId, itemType, HttpContext.Caller().AccountId, false, body.Reason), HttpContext.RequestAborted);
}

/// <summary>Level 2 sessions (PRD §6.3, A-04).</summary>
[ApiController]
[Area("Verification")]
[Route("v1/admin/level2-sessions")]
[ErrorMap(typeof(VerificationErrorMap))]
[Admin(Permission = "level2:manage")]
public sealed class Level2SessionsController(IMediator mediator) : ControllerBase
{
    /// <summary>listLevel2Sessions.</summary>
    [HttpGet]
    public Task<Level2SessionListView> List([FromQuery] Guid? providerId, [FromQuery] string? status, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListLevel2Sessions(providerId, status, cursor, limit), HttpContext.RequestAborted);

    /// <summary>scheduleLevel2Session.</summary>
    [HttpPost]
    public async Task<IActionResult> Schedule([FromBody] Level2SessionInput body) =>
        StatusCode(201, await mediator.Send(new ScheduleLevel2Session(body), HttpContext.RequestAborted));

    /// <summary>getLevel2Session.</summary>
    [HttpGet("{sessionId}")]
    public Task<Level2SessionView> Get(Guid sessionId) =>
        mediator.Send(new GetLevel2Session(sessionId), HttpContext.RequestAborted);

    /// <summary>recordLevel2Result.</summary>
    [HttpPost("{sessionId}/result")]
    public Task<Level2SessionView> Record(Guid sessionId, [FromBody] Level2ResultInput body) =>
        mediator.Send(new RecordLevel2Result(sessionId, HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);
}
