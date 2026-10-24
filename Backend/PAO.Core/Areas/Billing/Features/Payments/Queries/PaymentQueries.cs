using FluentValidation;
using PAO.Core.Areas.Billing.Services;
using PAO.EF.Billing;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Features.Payments.Queries;

/// <summary>Payment submissions, newest first: one merchant's (partner app) or the admin queue filtered by status.</summary>
public sealed record ListPayments(Guid? ProviderId, string? Status, string? Cursor, int? Limit) : IQuery<PaymentSubmissionListView>;

/// <summary>Checks <see cref="ListPayments"/>.</summary>
public sealed class ListPaymentsValidator : AbstractValidator<ListPayments>
{
    private static readonly HashSet<string?> Statuses = [null, BillingKinds.Pending, BillingKinds.Confirmed, BillingKinds.Rejected];

    /// <summary>A known status or none.</summary>
    public ListPaymentsValidator() => RuleFor(r => r.Status).Must(Statuses.Contains);
}

/// <summary>Answers <see cref="ListPayments"/>.</summary>
public sealed class ListPaymentsHandler(BillingAccounts accounts, IMapper mapper) : IRequestHandler<ListPayments, PaymentSubmissionListView>
{
    /// <inheritdoc />
    public async Task<PaymentSubmissionListView> Handle(ListPayments request, CancellationToken cancellationToken)
    {
        var page = await accounts.Submissions(request.ProviderId, request.Status, request.Cursor, request.Limit, cancellationToken);
        return new PaymentSubmissionListView { Items = mapper.MapAll<PaymentSubmissionRecord, PaymentSubmissionView>(page.Items), NextCursor = page.NextCursor };
    }
}
