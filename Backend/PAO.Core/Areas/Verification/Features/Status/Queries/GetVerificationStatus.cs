using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Status.Queries;

/// <summary>getVerificationStatus: the merchant's own verification screen (M14/P-03).</summary>
public sealed record GetVerificationStatus(Guid Merchant) : IQuery<VerificationStatusView>;

/// <summary>Answers <see cref="GetVerificationStatus"/>.</summary>
public sealed class GetVerificationStatusHandler(MerchantStatus status) : IRequestHandler<GetVerificationStatus, VerificationStatusView>
{
    /// <inheritdoc />
    public Task<VerificationStatusView> Handle(GetVerificationStatus request, CancellationToken cancellationToken) =>
        status.Status(request.Merchant, cancellationToken);
}
