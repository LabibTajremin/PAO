using FluentValidation;
using PAO.Core.Areas.Audit.Services;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Audit.Features.ListAuditEntries.Queries;

/// <summary>The audit log viewer's page (A-08); the spec has already checked the formats.</summary>
public sealed record ListAuditEntriesQuery(AuditFilter Filter, string? Cursor, int? Limit) : IQuery<AuditListView>;

/// <summary>Validates <see cref="ListAuditEntriesQuery"/>.</summary>
public sealed class ListAuditEntriesValidator : AbstractValidator<ListAuditEntriesQuery>
{
    /// <summary>The rules.</summary>
    public ListAuditEntriesValidator() => RuleFor(q => q.Filter).NotNull();
}

/// <summary>Reads one entry more than the page to know whether another page follows.</summary>
public sealed class ListAuditEntriesHandler(AuditLog log, IMapper mapper) : IRequestHandler<ListAuditEntriesQuery, AuditListView>
{
    /// <inheritdoc />
    public async Task<AuditListView> Handle(ListAuditEntriesQuery request, CancellationToken cancellationToken)
    {
        var cursor = Cursor.Decode(request.Cursor);
        var limit = Cursor.PageSize(request.Limit);
        var page = cursor is null
            ? new AuditPage(limit + 1)
            : new AuditPage(limit + 1, DateTimeOffset.Parse(cursor.CreatedAt, System.Globalization.CultureInfo.InvariantCulture), Guid.Parse(cursor.Id));
        var entries = await log.List(request.Filter, page, cancellationToken);
        var items = entries.Take(limit).ToList();
        var next = entries.Count > limit ? new Cursor(items[^1].At.ToUniversalTime().ToString("O", System.Globalization.CultureInfo.InvariantCulture), items[^1].Id.ToString()).Encode() : null;
        return new AuditListView { Items = mapper.MapAll<AuditEntry, AuditEntryView>(items), NextCursor = next };
    }
}
