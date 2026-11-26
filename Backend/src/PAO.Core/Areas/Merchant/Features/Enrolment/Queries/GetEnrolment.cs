using PAO.Core.Areas.Merchant.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.Enrolment.Queries;

/// <summary>The wizard progress; saved steps survive app restarts (M05–M13).</summary>
public sealed record GetEnrolment(Guid MerchantId) : IQuery<EnrolmentStatus>;

/// <summary>Answers <see cref="GetEnrolment"/>.</summary>
public sealed class GetEnrolmentHandler(MerchantEnrolment enrolment) : IRequestHandler<GetEnrolment, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(GetEnrolment request, CancellationToken cancellationToken) =>
        enrolment.Progress(request.MerchantId, cancellationToken);
}
