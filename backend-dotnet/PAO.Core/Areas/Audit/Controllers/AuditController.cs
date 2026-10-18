using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Audit.Features.ListAuditEntries.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Audit.Controllers;

/// <summary>The audit log viewer (A-08).</summary>
[ApiController]
[Area("Audit")]
[Route("v1/admin/audit")]
public sealed class AuditController(IMediator mediator) : ControllerBase
{
    /// <summary>listAuditEntries: filtered, newest first, cursor-paged.</summary>
    [HttpGet]
    [Admin(Permission = "audit:read")]
    public Task<AuditListView> List(
        [FromQuery] Guid? actorId, [FromQuery] string? action, [FromQuery] string? subjectId,
        [FromQuery] DateTimeOffset? from, [FromQuery] DateTimeOffset? to, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListAuditEntriesQuery(
            new AuditFilter { ActorId = actorId, Action = action, SubjectId = subjectId, From = from, To = to }, cursor, limit));
}
