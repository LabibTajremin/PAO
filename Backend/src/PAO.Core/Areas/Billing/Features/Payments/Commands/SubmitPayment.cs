using FluentValidation;
using PAO.Core.Areas.Billing.Repositories;
using PAO.Core.Areas.Billing.Services;
using PAO.EF.Billing;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Features.Payments.Commands;

/// <summary>A merchant reports a payment of the due for an admin to review (ADR-0035 §4).</summary>
public sealed record SubmitPayment(Guid ProviderId, PaymentInput Input) : ICommand<PaymentSubmissionView>;

/// <summary>Checks <see cref="SubmitPayment"/>; the spec has checked the shape, this repeats the rules a direct caller could miss.</summary>
public sealed class SubmitPaymentValidator : AbstractValidator<SubmitPayment>
{
    /// <summary>A positive amount, a known method and a reference.</summary>
    public SubmitPaymentValidator()
    {
        RuleFor(r => r.Input.AmountPaisa).GreaterThan(0);
        RuleFor(r => r.Input.Method).Must(BillingRules.Methods.Contains);
        RuleFor(r => r.Input.Reference).Must(s => s.Trim().Length is > 0 and <= 120);
    }
}

/// <summary>Answers <see cref="SubmitPayment"/>; the merchant is notified and the step audited through `billing.PaymentSubmitted`.</summary>
public sealed class SubmitPaymentHandler(BillingRepository repository, BillingAccounts accounts, IClock clock, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<SubmitPayment, PaymentSubmissionView>
{
    /// <inheritdoc />
    public async Task<PaymentSubmissionView> Handle(SubmitPayment request, CancellationToken cancellationToken)
    {
        var s = new PaymentSubmissionRecord
        {
            Id = ids.NewId(),
            ProviderId = request.ProviderId,
            AmountPaisa = request.Input.AmountPaisa,
            Method = request.Input.Method,
            Reference = request.Input.Reference.Trim(),
            Status = BillingKinds.Pending,
            Reason = string.Empty,
            CreatedAt = clock.Now,
        };
        await repository.AddSubmission(s, cancellationToken);
        var due = await accounts.Due(s.ProviderId, cancellationToken);
        await repository.Publish(s.ProviderId, PaymentSteps.Event(new PaymentSubmitted(), s, due, request.ProviderId), cancellationToken);
        return mapper.Map<PaymentSubmissionRecord, PaymentSubmissionView>(s);
    }
}
