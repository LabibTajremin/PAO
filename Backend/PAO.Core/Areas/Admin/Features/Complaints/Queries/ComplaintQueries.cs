using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Complaints.Queries;

/// <summary>A page of the support queue, newest first (A-07).</summary>
public sealed record ListComplaints(string? Status, Guid? AssigneeId, string? Cursor, int? Limit) : IQuery<PageView<ComplaintView>>;

/// <summary>One complaint with its notes.</summary>
public sealed record GetComplaint(Guid ComplaintId) : IQuery<ComplaintView>;

/// <summary>Checks <see cref="ListComplaints"/>.</summary>
public sealed class ListComplaintsValidator : AbstractValidator<ListComplaints>
{
    /// <summary>The spec has checked the formats.</summary>
    public ListComplaintsValidator() => RuleFor(r => r.Limit).GreaterThan(0).When(r => r.Limit is not null);
}

/// <summary>Answers <see cref="ListComplaints"/>.</summary>
public sealed class ListComplaintsHandler(ComplaintRepository repository, IMapper mapper) : IRequestHandler<ListComplaints, PageView<ComplaintView>>
{
    /// <inheritdoc />
    public async Task<PageView<ComplaintView>> Handle(ListComplaints request, CancellationToken cancellationToken)
    {
        var size = Cursor.PageSize(request.Limit);
        var (at, id) = ComplaintSteps.After(request.Cursor);
        var rows = await repository.List(new ComplaintFilter(request.Status, request.AssigneeId, at, id, size + 1), cancellationToken);
        return ComplaintSteps.Page(rows, size, c => (c.Row.CreatedAt, c.Row.Id), mapper.Views);
    }
}

/// <summary>Answers <see cref="GetComplaint"/>.</summary>
public sealed class GetComplaintHandler(ComplaintRepository repository, IMapper mapper) : IRequestHandler<GetComplaint, ComplaintView>
{
    /// <inheritdoc />
    public async Task<ComplaintView> Handle(GetComplaint request, CancellationToken cancellationToken) =>
        mapper.Map<Complaint, ComplaintView>(await repository.Get(request.ComplaintId, cancellationToken));
}
