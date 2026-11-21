using PAO.Core.Areas.Billing.Features.Commission.Commands;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Services.Shared;

/// <summary>The Billing contract for the other areas: Booking checks the due before an accept.</summary>
public sealed class BillingSharedService(BillingAccounts accounts, IMediator mediator, IMapper mapper) : IBillingSharedService
{
    /// <inheritdoc />
    public async Task<DueStatus> GetDueStatus(Guid merchantId, CancellationToken cancellationToken) =>
        mapper.Map<DueWithLimits, DueStatus>(await accounts.Due(merchantId, cancellationToken));

    /// <inheritdoc />
    public Task RecordCommission(CommissionRequest request, CancellationToken cancellationToken) =>
        mediator.Send(new ChargeCommission(request), cancellationToken);
}
