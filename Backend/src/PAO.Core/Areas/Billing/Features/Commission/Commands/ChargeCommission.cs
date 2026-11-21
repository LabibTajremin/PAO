using FluentValidation;
using PAO.Core.Areas.Billing.Repositories;
using PAO.Core.Areas.Billing.Services;
using PAO.EF.Billing;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Features.Commission.Commands;

/// <summary>Debits PAO's commission on a completed job (ADR-0035 §2); sent for `booking.BookingCompleted`.</summary>
public sealed record ChargeCommission(CommissionRequest Job) : ICommand;

/// <summary>Checks <see cref="ChargeCommission"/>.</summary>
public sealed class ChargeCommissionValidator : AbstractValidator<ChargeCommission>
{
    /// <summary>A booking and a merchant.</summary>
    public ChargeCommissionValidator()
    {
        RuleFor(r => r.Job.BookingId).NotEmpty();
        RuleFor(r => r.Job.MerchantId).NotEmpty();
    }
}

/// <summary>
/// Answers <see cref="ChargeCommission"/>. The rate is read when the job completes and kept on
/// the entry, so a later change of the setting does not reprice old jobs. A second delivery
/// of the same completion changes nothing.
/// </summary>
public sealed class ChargeCommissionHandler(BillingRepository repository, BillingAccounts accounts, IClock clock, IIdGenerator ids) : IRequestHandler<ChargeCommission, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(ChargeCommission request, CancellationToken cancellationToken)
    {
        var job = request.Job;
        var rate = await accounts.Rate(cancellationToken);
        var entry = new LedgerEntryRecord
        {
            Id = ids.NewId(),
            ProviderId = job.MerchantId,
            Kind = BillingKinds.Commission,
            AmountPaisa = BillingRules.Commission(job.FinalPricePaisa, rate),
            BookingId = job.BookingId,
            BookingNumber = job.BookingNumber == 0 ? null : job.BookingNumber,
            JobTotalPaisa = job.FinalPricePaisa,
            RateBp = rate,
            CreatedAt = clock.Now,
        };
        if (await repository.AddCommission(entry, cancellationToken) && entry.AmountPaisa > 0)
        {
            var due = await accounts.Due(job.MerchantId, cancellationToken);
            await repository.Publish(job.MerchantId, new CommissionCharged
            {
                ProviderId = job.MerchantId,
                BookingId = job.BookingId,
                AmountPaisa = entry.AmountPaisa,
                DuePaisa = due.Totals.DuePaisa,
                Blocked = due.Blocked,
            }, cancellationToken);
        }
        return Unit.Value;
    }
}
