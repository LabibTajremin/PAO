using System.Globalization;
using PAO.Core.Areas.Verification.Repositories;
using PAO.Core.Areas.Verification.Services;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Review.Queries;

/// <summary>listVerificationQueue (A-03): submitted merchants with pending items, oldest first.</summary>
public sealed record ListVerificationQueue(string? ItemType, Guid? ServiceId, string? Cursor, int? Limit) : IQuery<VerificationQueueView>;

/// <summary>getVerificationReview (A06).</summary>
public sealed record GetVerificationReview(Guid Merchant) : IQuery<VerificationReviewView>;

/// <summary>Answers <see cref="ListVerificationQueue"/> with a look-ahead row to know whether a next page exists.</summary>
public sealed class ListVerificationQueueHandler(VerificationRepository repository, ReviewItems reviews) : IRequestHandler<ListVerificationQueue, VerificationQueueView>
{
    /// <inheritdoc />
    public async Task<VerificationQueueView> Handle(ListVerificationQueue request, CancellationToken cancellationToken)
    {
        var size = Cursor.PageSize(request.Limit);
        var rows = await repository.Queue(request.ItemType, request.ServiceId, PageOf(request.Cursor, size), cancellationToken);
        var shown = rows.Take(size).ToList();
        var next = rows.Count > size ? new Cursor(shown[^1].SubmittedAt.ToString("O", CultureInfo.InvariantCulture), shown[^1].ProviderId.ToString()).Encode() : null;
        return new VerificationQueueView { Items = await reviews.Queue(shown, cancellationToken), NextCursor = next };
    }

    /// <summary>A keyset page asking for one look-ahead row; a malformed cursor is a 422.</summary>
    public static Page PageOf(string? text, int size) =>
        Cursor.Decode(text) is { } c
            ? new Page(DateTimeOffset.Parse(c.CreatedAt, CultureInfo.InvariantCulture), Guid.Parse(c.Id), size + 1)
            : new Page(null, null, size + 1);
}

/// <summary>Answers <see cref="GetVerificationReview"/>.</summary>
public sealed class GetVerificationReviewHandler(ReviewItems reviews) : IRequestHandler<GetVerificationReview, VerificationReviewView>
{
    /// <inheritdoc />
    public Task<VerificationReviewView> Handle(GetVerificationReview request, CancellationToken cancellationToken) =>
        reviews.Review(request.Merchant, cancellationToken);
}
