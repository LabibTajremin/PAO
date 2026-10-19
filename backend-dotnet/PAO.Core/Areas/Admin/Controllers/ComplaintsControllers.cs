using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Admin.Features.Complaints.Commands;
using PAO.Core.Areas.Admin.Features.Complaints.Queries;
using PAO.Core.Areas.Admin.Features.Reports.Commands;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Controllers;

/// <summary>Admin failures as API errors, equal to the Go and NestJS map.</summary>
public sealed class AdminErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [AdminReasons.SettingNotFound] = ApiErrors.NotFound,
        [AdminReasons.SettingInvalid] = new(422, "SETTING_INVALID", "This value does not fit the setting."),
        [AdminReasons.ComplaintNotFound] = ApiErrors.NotFound,
        [AdminReasons.BookingNotFound] = ApiErrors.NotFound,
        [AdminReasons.ComplaintInvalid] = ApiErrors.ValidationFailed,
        [AdminReasons.PhotoInvalid] = new(422, "UPLOAD_INVALID", "Attach confirmed complaint photos only."),
        [AdminReasons.AssigneeInvalid] = new(422, "VALIDATION_FAILED", "This admin cannot work complaints."),
        [AdminReasons.AlreadyResolved] = new(409, "COMPLAINT_INVALID_TRANSITION", "This complaint is already resolved."),
        [AdminReasons.PersonNotFound] = ApiErrors.NotFound,
        [IdentityErrors.StatusInvalid] = new(409, "CONFLICT", "The account already has this status."),
    };
}

/// <summary>The support queue (A-07).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/complaints")]
[ErrorMap(typeof(AdminErrorMap))]
[Admin(Permission = "complaint:manage")]
public sealed class ComplaintsController(IMediator mediator) : ControllerBase
{
    /// <summary>listComplaints.</summary>
    [HttpGet]
    public Task<PageView<ComplaintView>> List([FromQuery] string? status, [FromQuery] Guid? assigneeId, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListComplaints(status, assigneeId, cursor, limit), HttpContext.RequestAborted);

    /// <summary>getComplaint.</summary>
    [HttpGet("{complaintId}")]
    public Task<ComplaintView> Get(Guid complaintId) => mediator.Send(new GetComplaint(complaintId), HttpContext.RequestAborted);

    /// <summary>assignComplaint.</summary>
    [HttpPost("{complaintId}/assign")]
    public Task<ComplaintView> Assign(Guid complaintId, [FromBody] ComplaintAssignInput body) =>
        mediator.Send(new AssignComplaint(complaintId, body.AssigneeId), HttpContext.RequestAborted);

    /// <summary>commentOnComplaint.</summary>
    [HttpPost("{complaintId}/comments")]
    public async Task<IActionResult> Comment(Guid complaintId, [FromBody] ComplaintCommentInput body) =>
        StatusCode(201, await mediator.Send(new CommentOnComplaint(complaintId, HttpContext.Caller().AccountId, body.Body), HttpContext.RequestAborted));

    /// <summary>resolveComplaint.</summary>
    [HttpPost("{complaintId}/resolve")]
    public Task<ComplaintView> Resolve(Guid complaintId, [FromBody] ComplaintResolveInput body) =>
        mediator.Send(new ResolveComplaint(complaintId, HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);
}

/// <summary>A customer or a provider reports a problem with a booking (C-14).</summary>
[ApiController]
[Area("Admin")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class ReportsController(IMediator mediator) : ControllerBase
{
    /// <summary>reportCustomerProblem.</summary>
    [HttpPost("/v1/customer/bookings/{bookingId}/reports")]
    [AllUserType(Permission = "complaint:create")]
    public Task<IActionResult> Customer(Guid bookingId, [FromBody] ComplaintInput body) => Report("customer", bookingId, body);

    /// <summary>reportProviderProblem.</summary>
    [HttpPost("/v1/provider/jobs/{bookingId}/reports")]
    [AllUserType(Permission = "complaint:create")]
    public Task<IActionResult> Provider(Guid bookingId, [FromBody] ComplaintInput body) => Report("provider", bookingId, body);

    private async Task<IActionResult> Report(string role, Guid bookingId, ComplaintInput body) =>
        StatusCode(201, await mediator.Send(new ReportProblem(HttpContext.Caller().AccountId, role, bookingId, body), HttpContext.RequestAborted));
}
