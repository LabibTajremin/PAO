using System.Globalization;
using PAO.Core.Areas.Verification.Features.Review.Queries;
using PAO.Core.Areas.Verification.Repositories;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Level2.Queries;

/// <summary>listLevel2Sessions: newest first, optionally for one merchant or status.</summary>
public sealed record ListLevel2Sessions(Guid? Merchant, string? Status, string? Cursor, int? Limit) : IQuery<Level2SessionListView>;

/// <summary>getLevel2Session.</summary>
public sealed record GetLevel2Session(Guid Session) : IQuery<Level2SessionView>;

/// <summary>Answers <see cref="ListLevel2Sessions"/> with a look-ahead row to know whether a next page exists.</summary>
public sealed class ListLevel2SessionsHandler(VerificationRepository repository, IMapper mapper) : IRequestHandler<ListLevel2Sessions, Level2SessionListView>
{
    /// <inheritdoc />
    public async Task<Level2SessionListView> Handle(ListLevel2Sessions request, CancellationToken cancellationToken)
    {
        var size = Cursor.PageSize(request.Limit);
        var page = ListVerificationQueueHandler.PageOf(request.Cursor, size);
        var rows = await repository.Sessions(request.Merchant, request.Status, page, cancellationToken);
        var shown = rows.Take(size).ToList();
        var next = rows.Count > size ? new Cursor(shown[^1].CreatedAt.ToString("O", CultureInfo.InvariantCulture), shown[^1].Id.ToString()).Encode() : null;
        return new Level2SessionListView { Items = mapper.MapAll<Level2SessionState, Level2SessionView>(shown), NextCursor = next };
    }
}

/// <summary>Answers <see cref="GetLevel2Session"/>.</summary>
public sealed class GetLevel2SessionHandler(VerificationRepository repository, IMapper mapper) : IRequestHandler<GetLevel2Session, Level2SessionView>
{
    /// <inheritdoc />
    public async Task<Level2SessionView> Handle(GetLevel2Session request, CancellationToken cancellationToken) =>
        mapper.Map<Level2SessionState, Level2SessionView>(await repository.Session(request.Session, cancellationToken));
}
