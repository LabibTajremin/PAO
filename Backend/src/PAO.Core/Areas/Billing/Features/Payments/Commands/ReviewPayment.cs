using FluentValidation;
using PAO.Core.Areas.Billing.Repositories;
using PAO.Core.Areas.Billing.Services;
using PAO.EF.Billing;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Features.Payments.Commands;

/// <summary>An admin confirms a payment: the ledger is credited, which can lift the block (ADR-0035 §4).</summary>
public sealed record ConfirmPayment(Guid ActorId, Guid SubmissionId) : ICommand<PaymentSubmissionView>;

/// <summary>An admin rejects a payment; a reason is required (ADR-0035 §4).</summary>
public sealed record RejectPayment(Guid ActorId, Guid SubmissionId, RejectInput Input) : ICommand<PaymentSubmissionView>;

/// <summary>Checks <see cref="ConfirmPayment"/>.</summary>
public sealed class ConfirmPaymentValidator : AbstractValidator<ConfirmPayment>
{
    /// <summary>A submission.</summary>
    public ConfirmPaymentValidator() => RuleFor(r => r.SubmissionId).NotEmpty();
}

/// <summary>Checks <see cref="RejectPayment"/>.</summary>
public sealed class RejectPaymentValidator : AbstractValidator<RejectPayment>
{
    /// <summary>A reason of 3 to 500 characters once trimmed.</summary>
    public RejectPaymentValidator() => RuleFor(r => r.Input.Reason).Must(s => s.Trim().Length is >= 3 and <= 500);
}

/// <summary>Answers <see cref="ConfirmPayment"/>; `billing.PaymentConfirmed` notifies the merchant and is audited.</summary>
public sealed class ConfirmPaymentHandler(BillingRepository repository, BillingAccounts accounts, IClock clock, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<ConfirmPayment, PaymentSubmissionView>
{
    /// <inheritdoc />
    public async Task<PaymentSubmissionView> Handle(ConfirmPayment request, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        var s = await repository.Review(request.SubmissionId, BillingKinds.Confirmed, request.ActorId, string.Empty, now, cancellationToken);
        await repository.AddCredit(s, ids.NewId(), now, cancellationToken);
        var due = await accounts.Due(s.ProviderId, cancellationToken);
        await repository.Publish(s.ProviderId, PaymentSteps.Event(new PaymentConfirmed(), s, due, request.ActorId), cancellationToken);
        return mapper.Map<PaymentSubmissionRecord, PaymentSubmissionView>(s);
    }
}

/// <summary>Answers <see cref="RejectPayment"/>; `billing.PaymentRejected` carries the reason to the merchant and the audit log.</summary>
public sealed class RejectPaymentHandler(BillingRepository repository, BillingAccounts accounts, IClock clock, IMapper mapper)
    : IRequestHandler<RejectPayment, PaymentSubmissionView>
{
    /// <inheritdoc />
    public async Task<PaymentSubmissionView> Handle(RejectPayment request, CancellationToken cancellationToken)
    {
        var s = await repository.Review(request.SubmissionId, BillingKinds.Rejected, request.ActorId, request.Input.Reason.Trim(), clock.Now, cancellationToken);
        var due = await accounts.Due(s.ProviderId, cancellationToken);
        await repository.Publish(s.ProviderId, PaymentSteps.Event(new PaymentRejected(), s, due, request.ActorId), cancellationToken);
        return mapper.Map<PaymentSubmissionRecord, PaymentSubmissionView>(s);
    }
}
