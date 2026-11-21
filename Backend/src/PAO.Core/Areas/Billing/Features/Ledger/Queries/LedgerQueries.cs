using FluentValidation;
using PAO.Core.Areas.Billing.Services;
using PAO.EF.Billing;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Billing.Features.Ledger.Queries;

/// <summary>A merchant's due against the block limit: the partner app's due banner (ADR-0035 §3).</summary>
public sealed record GetDue(Guid ProviderId) : IQuery<DueSummaryView>;

/// <summary>A merchant's ledger, newest first.</summary>
public sealed record ListLedger(Guid ProviderId, string? Cursor, int? Limit) : IQuery<LedgerEntryListView>;

/// <summary>A merchant's due and ledger for the admin console.</summary>
public sealed record GetMerchantLedger(Guid ProviderId, string? Cursor, int? Limit) : IQuery<MerchantLedgerView>;

/// <summary>Checks <see cref="GetDue"/>.</summary>
public sealed class GetDueValidator : AbstractValidator<GetDue>
{
    /// <summary>The caller.</summary>
    public GetDueValidator() => RuleFor(r => r.ProviderId).NotEmpty();
}

/// <summary>Checks <see cref="ListLedger"/>.</summary>
public sealed class ListLedgerValidator : AbstractValidator<ListLedger>
{
    /// <summary>The caller; the spec has checked the paging formats.</summary>
    public ListLedgerValidator() => RuleFor(r => r.ProviderId).NotEmpty();
}

/// <summary>Checks <see cref="GetMerchantLedger"/>.</summary>
public sealed class GetMerchantLedgerValidator : AbstractValidator<GetMerchantLedger>
{
    /// <summary>A merchant; an unknown one has an empty ledger.</summary>
    public GetMerchantLedgerValidator() => RuleFor(r => r.ProviderId).NotEmpty();
}

/// <summary>Answers <see cref="GetDue"/>.</summary>
public sealed class GetDueHandler(BillingAccounts accounts, IMapper mapper) : IRequestHandler<GetDue, DueSummaryView>
{
    /// <inheritdoc />
    public async Task<DueSummaryView> Handle(GetDue request, CancellationToken cancellationToken) =>
        mapper.Map<DueWithLimits, DueSummaryView>(await accounts.Due(request.ProviderId, cancellationToken));
}

/// <summary>Answers <see cref="ListLedger"/>.</summary>
public sealed class ListLedgerHandler(BillingAccounts accounts, IMapper mapper) : IRequestHandler<ListLedger, LedgerEntryListView>
{
    /// <inheritdoc />
    public async Task<LedgerEntryListView> Handle(ListLedger request, CancellationToken cancellationToken)
    {
        var page = await accounts.Ledger(request.ProviderId, request.Cursor, request.Limit, cancellationToken);
        return new LedgerEntryListView { Items = mapper.MapAll<LedgerEntryRecord, LedgerEntryView>(page.Items), NextCursor = page.NextCursor };
    }
}

/// <summary>Answers <see cref="GetMerchantLedger"/>.</summary>
public sealed class GetMerchantLedgerHandler(BillingAccounts accounts, IMapper mapper) : IRequestHandler<GetMerchantLedger, MerchantLedgerView>
{
    /// <inheritdoc />
    public async Task<MerchantLedgerView> Handle(GetMerchantLedger request, CancellationToken cancellationToken)
    {
        var due = await accounts.Due(request.ProviderId, cancellationToken);
        var page = await accounts.Ledger(request.ProviderId, request.Cursor, request.Limit, cancellationToken);
        return new MerchantLedgerView
        {
            ProviderId = request.ProviderId,
            Summary = mapper.Map<DueWithLimits, DueSummaryView>(due),
            Entries = new LedgerEntryListView { Items = mapper.MapAll<LedgerEntryRecord, LedgerEntryView>(page.Items), NextCursor = page.NextCursor },
        };
    }
}
