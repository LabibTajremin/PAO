using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Reports.Commands;

/// <summary>
/// Files a complaint by one party of a booking against the other (C-14). A stranger to the
/// booking gets `admin.booking_not_found`, so booking ids cannot be probed.
/// </summary>
public sealed record ReportProblem(Guid ReporterId, string ReporterRole, Guid BookingId, ComplaintInput Input) : ICommand<ComplaintView>;

/// <summary>Checks <see cref="ReportProblem"/> with the reason the error map knows.</summary>
public sealed class ReportProblemValidator : AbstractValidator<ReportProblem>
{
    /// <summary>A known reason, 10 to 1000 characters and up to five distinct photos.</summary>
    public ReportProblemValidator() => RuleFor(r => r.Input).Custom((input, _) =>
    {
        if (!AdminRules.IsValidReport(input))
        {
            throw new DomainException(AdminReasons.ComplaintInvalid);
        }
    });
}

/// <summary>Answers <see cref="ReportProblem"/>.</summary>
public sealed class ReportProblemHandler(ComplaintRepository repository, AdminPeers peers, IClock clock, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<ReportProblem, ComplaintView>
{
    /// <inheritdoc />
    public async Task<ComplaintView> Handle(ReportProblem request, CancellationToken cancellationToken)
    {
        var (customerId, providerId) = await peers.Parties(request.BookingId, cancellationToken);
        var (me, other) = request.ReporterRole == "customer" ? (customerId, providerId) : (providerId, customerId);
        if (me != request.ReporterId)
        {
            throw new DomainException(AdminReasons.BookingNotFound);
        }
        var photos = request.Input.PhotoMediaIds ?? [];
        await peers.AttachPhotos(request.ReporterId, photos, cancellationToken);
        var now = clock.Now;
        var row = new ComplaintRecord
        {
            Id = ids.NewId(), BookingId = request.BookingId, ReporterId = request.ReporterId, ReporterRole = request.ReporterRole, AgainstId = other,
            Reason = request.Input.Reason, Description = request.Input.Description, PhotoMediaIds = [.. photos], Status = "open", Resolution = string.Empty,
            CreatedAt = now, UpdatedAt = now,
        };
        var stored = await repository.Create(row, c => new ComplaintCreated
        {
            ComplaintId = c.Row.Id,
            TicketNumber = c.TicketNumber,
            BookingId = c.Row.BookingId,
            ReporterId = c.Row.ReporterId,
            ReporterRole = c.Row.ReporterRole,
            AgainstId = c.Row.AgainstId,
        }, cancellationToken);
        return mapper.Map<Complaint, ComplaintView>(stored);
    }
}
