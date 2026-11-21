using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Complaints.Commands;

/// <summary>Hands a complaint to an admin who may work the queue; reassigning is allowed until it is resolved.</summary>
public sealed record AssignComplaint(Guid ComplaintId, Guid AssigneeId) : ICommand<ComplaintView>;

/// <summary>Adds an internal note and returns the complaint with every note.</summary>
public sealed record CommentOnComplaint(Guid ComplaintId, Guid AuthorId, string Body) : ICommand<ComplaintView>;

/// <summary>
/// Closes a complaint. `ComplaintResolved` tells the reporter and, when verified, feeds the
/// provider quality review (PRD §6.4).
/// </summary>
public sealed record ResolveComplaint(Guid ComplaintId, Guid ActorId, ComplaintResolveInput Input) : ICommand<ComplaintView>;

/// <summary>Checks <see cref="CommentOnComplaint"/>.</summary>
public sealed class CommentOnComplaintValidator : AbstractValidator<CommentOnComplaint>
{
    /// <summary>The spec bounds the note.</summary>
    public CommentOnComplaintValidator() => RuleFor(r => r.Body).NotNull();
}

/// <summary>Checks <see cref="AssignComplaint"/>.</summary>
public sealed class AssignComplaintValidator : AbstractValidator<AssignComplaint>
{
    /// <summary>The spec has checked the id.</summary>
    public AssignComplaintValidator() => RuleFor(r => r.AssigneeId).NotNull();
}

/// <summary>Checks <see cref="ResolveComplaint"/>.</summary>
public sealed class ResolveComplaintValidator : AbstractValidator<ResolveComplaint>
{
    /// <summary>The note's length is checked once the complaint is known to be open.</summary>
    public ResolveComplaintValidator() => RuleFor(r => r.Input).NotNull();
}

/// <summary>Answers <see cref="AssignComplaint"/>.</summary>
public sealed class AssignComplaintHandler(ComplaintRepository repository, AdminPeers peers, IClock clock, IMapper mapper) : IRequestHandler<AssignComplaint, ComplaintView>
{
    /// <inheritdoc />
    public async Task<ComplaintView> Handle(AssignComplaint request, CancellationToken cancellationToken)
    {
        if (!await peers.CanWorkComplaints(request.AssigneeId, cancellationToken))
        {
            throw new DomainException(AdminReasons.AssigneeInvalid);
        }
        await repository.Save(request.ComplaintId, c =>
        {
            ComplaintSteps.Unresolved(c);
            c.Status = "assigned";
            c.AssigneeId = request.AssigneeId;
            c.UpdatedAt = clock.Now;
            return null;
        }, cancellationToken);
        return mapper.Map<Complaint, ComplaintView>(await repository.Get(request.ComplaintId, cancellationToken));
    }
}

/// <summary>Answers <see cref="CommentOnComplaint"/>.</summary>
public sealed class CommentOnComplaintHandler(ComplaintRepository repository, IClock clock, IIdGenerator ids, IMapper mapper) : IRequestHandler<CommentOnComplaint, ComplaintView>
{
    /// <inheritdoc />
    public async Task<ComplaintView> Handle(CommentOnComplaint request, CancellationToken cancellationToken)
    {
        await repository.Get(request.ComplaintId, cancellationToken);
        await repository.AddComment(new ComplaintCommentRecord
        {
            Id = ids.NewId(),
            ComplaintId = request.ComplaintId,
            AuthorId = request.AuthorId,
            Body = request.Body,
            At = clock.Now,
        }, cancellationToken);
        return mapper.Map<Complaint, ComplaintView>(await repository.Get(request.ComplaintId, cancellationToken));
    }
}

/// <summary>Answers <see cref="ResolveComplaint"/>.</summary>
public sealed class ResolveComplaintHandler(ComplaintRepository repository, IClock clock, IMapper mapper) : IRequestHandler<ResolveComplaint, ComplaintView>
{
    /// <inheritdoc />
    public async Task<ComplaintView> Handle(ResolveComplaint request, CancellationToken cancellationToken)
    {
        var (note, verified) = (request.Input.Resolution, request.Input.Verified);
        await repository.Save(request.ComplaintId, c =>
        {
            ComplaintSteps.Unresolved(c);
            if (!AdminRules.IsValidResolution(note))
            {
                throw new DomainException(AdminReasons.ComplaintInvalid);
            }
            var now = clock.Now;
            (c.Status, c.Resolution, c.Verified, c.UpdatedAt, c.ResolvedAt) = ("resolved", note, verified, now, now);
            return new ComplaintResolved
            {
                ComplaintId = c.Id,
                TicketNumber = Tickets.Format(c.TicketNumber),
                BookingId = c.BookingId,
                ReporterId = c.ReporterId,
                ReporterRole = c.ReporterRole,
                AgainstId = c.AgainstId,
                Verified = verified,
                ActorId = request.ActorId,
            };
        }, cancellationToken);
        return mapper.Map<Complaint, ComplaintView>(await repository.Get(request.ComplaintId, cancellationToken));
    }
}
