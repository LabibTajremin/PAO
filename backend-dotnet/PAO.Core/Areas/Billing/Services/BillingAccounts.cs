using System.Globalization;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Billing.Repositories;
using PAO.EF.Billing;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Billing;

namespace PAO.Core.Areas.Billing.Services;

/// <summary>A page of rows with the cursor of the next one.</summary>
public sealed record Page<T>(IReadOnlyList<T> Items, string? NextCursor);

/// <summary>The due of a merchant judged by the admin settings, and the ledger paging every handler shares.</summary>
public sealed class BillingAccounts(BillingRepository repository, IAdminSharedService admin)
{
    /// <summary>The merchant's totals with the current rate and block limit.</summary>
    public async Task<DueWithLimits> Due(Guid providerId, CancellationToken cancellationToken)
    {
        var settings = await admin.GetSettings(cancellationToken);
        var totals = await repository.Totals(providerId, cancellationToken);
        return new DueWithLimits(totals, settings.CommissionRateBp, settings.DueBlockAmountPaisa);
    }

    /// <summary>The current commission rate in basis points.</summary>
    public async Task<int> Rate(CancellationToken cancellationToken) => (await admin.GetSettings(cancellationToken)).CommissionRateBp;

    /// <summary>One page of the merchant's ledger; one look-ahead row tells whether another follows.</summary>
    public async Task<Page<LedgerEntryRecord>> Ledger(Guid providerId, string? cursor, int? limit, CancellationToken cancellationToken)
    {
        var (at, id, size) = Position(cursor, limit);
        var rows = await repository.Ledger(providerId, at, id, size + 1, cancellationToken);
        return Paged(rows, size, r => (r.CreatedAt, r.Id));
    }

    /// <summary>One page of submissions, filtered by merchant and status when given.</summary>
    public async Task<Page<PaymentSubmissionRecord>> Submissions(Guid? providerId, string? status, string? cursor, int? limit, CancellationToken cancellationToken)
    {
        var (at, id, size) = Position(cursor, limit);
        var rows = await repository.Submissions(providerId, status, at, id, size + 1, cancellationToken);
        return Paged(rows, size, r => (r.CreatedAt, r.Id));
    }

    private static (DateTimeOffset? At, Guid? Id, int Size) Position(string? text, int? limit)
    {
        var cursor = Cursor.Decode(text);
        DateTimeOffset? at = cursor is null ? null : DateTimeOffset.Parse(cursor.CreatedAt, CultureInfo.InvariantCulture).ToUniversalTime();
        return (at, cursor is null ? null : Guid.Parse(cursor.Id), Cursor.PageSize(limit));
    }

    private static Page<T> Paged<T>(List<T> rows, int size, Func<T, (DateTimeOffset At, Guid Id)> key)
    {
        var items = rows.Take(size).ToList();
        string? next = null;
        if (rows.Count > size)
        {
            var (at, id) = key(items[^1]);
            next = new Cursor(at.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture), id.ToString()).Encode();
        }
        return new Page<T>(items, next);
    }
}
