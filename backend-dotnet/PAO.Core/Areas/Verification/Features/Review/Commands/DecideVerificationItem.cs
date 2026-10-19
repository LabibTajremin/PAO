using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Review.Commands;

/// <summary>
/// approveVerificationItem and rejectVerificationItem: a verifier's decision on one item. A
/// rejection sends the item back to the merchant with the reason, which is how a verifier
/// asks for changes.
/// </summary>
public sealed record DecideVerificationItem(Guid Merchant, string Item, Guid Verifier, bool Approve, string Reason) : ICommand<VerificationReviewView>;

/// <summary>Answers <see cref="DecideVerificationItem"/>.</summary>
public sealed class DecideVerificationItemHandler(ReviewItems reviews) : IRequestHandler<DecideVerificationItem, VerificationReviewView>
{
    /// <inheritdoc />
    public Task<VerificationReviewView> Handle(DecideVerificationItem request, CancellationToken cancellationToken) =>
        reviews.Decide(request.Merchant, request.Item, request.Verifier, request.Approve, request.Reason, cancellationToken);
}
