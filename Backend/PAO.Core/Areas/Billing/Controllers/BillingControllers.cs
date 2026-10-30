using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Billing.Features.Ledger.Queries;
using PAO.Core.Areas.Billing.Features.Payments.Commands;
using PAO.Core.Areas.Billing.Features.Payments.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Controllers;

/// <summary>Billing failures as API errors (ADR-0035).</summary>
public sealed class BillingErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [BillingErrors.NotFound] = ApiErrors.NotFound,
        [BillingErrors.NotPending] = new(409, "PAYMENT_NOT_PENDING", "This payment was already reviewed."),
    };
}

/// <summary>The merchant's due, ledger and payments: the partner app's billing screens (ADR-0035).</summary>
[ApiController]
[Area("Billing")]
[Route("v1/provider/billing")]
[ErrorMap(typeof(BillingErrorMap))]
[Merchant(Permission = "provider:manage:own")]
public sealed class ProviderBillingController(IMediator mediator) : ControllerBase
{
    private Guid Me => HttpContext.Caller().AccountId;

    /// <summary>getMyDue.</summary>
    [HttpGet("summary")]
    public Task<DueSummaryView> Summary() => mediator.Send(new GetDue(Me), HttpContext.RequestAborted);

    /// <summary>listMyLedger.</summary>
    [HttpGet("ledger")]
    public Task<LedgerEntryListView> Ledger([FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListLedger(Me, cursor, limit), HttpContext.RequestAborted);

    /// <summary>listMyPayments.</summary>
    [HttpGet("payments")]
    public Task<PaymentSubmissionListView> Payments([FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListPayments(Me, null, cursor, limit), HttpContext.RequestAborted);

    /// <summary>submitPayment.</summary>
    [HttpPost("payments")]
    public async Task<IActionResult> Submit([FromBody] PaymentInput body) =>
        StatusCode(201, await mediator.Send(new SubmitPayment(Me, body), HttpContext.RequestAborted));
}

/// <summary>The admin console's payment queue and merchant ledgers (ADR-0035 §4).</summary>
[ApiController]
[Area("Billing")]
[Route("v1/admin/billing")]
[ErrorMap(typeof(BillingErrorMap))]
[Admin(Permission = "billing:manage")]
public sealed class AdminBillingController(IMediator mediator) : ControllerBase
{
    private Guid Me => HttpContext.Caller().AccountId;

    /// <summary>listPaymentSubmissions.</summary>
    [HttpGet("payments")]
    public Task<PaymentSubmissionListView> Payments([FromQuery] string? status, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListPayments(null, status, cursor, limit), HttpContext.RequestAborted);

    /// <summary>confirmPayment.</summary>
    [HttpPost("payments/{submissionId}/confirm")]
    public Task<PaymentSubmissionView> Confirm(Guid submissionId) =>
        mediator.Send(new ConfirmPayment(Me, submissionId), HttpContext.RequestAborted);

    /// <summary>rejectPayment.</summary>
    [HttpPost("payments/{submissionId}/reject")]
    public Task<PaymentSubmissionView> Reject(Guid submissionId, [FromBody] RejectInput body) =>
        mediator.Send(new RejectPayment(Me, submissionId, body), HttpContext.RequestAborted);

    /// <summary>getMerchantLedger.</summary>
    [HttpGet("merchants/{providerId}/ledger")]
    public Task<MerchantLedgerView> Ledger(Guid providerId, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new GetMerchantLedger(providerId, cursor, limit), HttpContext.RequestAborted);
}
