using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Billing;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Billing.Repositories;

/// <summary>The merchant ledger and payment submissions (`billing` schema).</summary>
public sealed class BillingRepository(PaoDbContext db, OutboxWriter outbox)
{
    /// <summary>The merchant's debits, credits and unreviewed payments, in one round trip.</summary>
    public async Task<DueTotals> Totals(Guid providerId, CancellationToken cancellationToken)
    {
        var row = await db.Database.SqlQuery<TotalsRow>($"""
            SELECT COALESCE(SUM(amount_paisa) FILTER (WHERE kind = 'commission'), 0)::bigint AS "DebitPaisa",
                   COALESCE(SUM(amount_paisa) FILTER (WHERE kind = 'payment'), 0)::bigint AS "CreditPaisa",
                   (SELECT COALESCE(SUM(amount_paisa), 0)::bigint FROM billing.payment_submissions
                    WHERE provider_id = {providerId} AND status = 'pending') AS "PendingPaisa"
            FROM billing.ledger_entries WHERE provider_id = {providerId}
            """).SingleAsync(cancellationToken);
        return new DueTotals(row.DebitPaisa, row.CreditPaisa, row.PendingPaisa);
    }

    /// <summary>
    /// Debits a commission unless the booking already has one; reports whether it was new, so
    /// a redelivered completion neither charges twice nor notifies twice.
    /// </summary>
    public async Task<bool> AddCommission(LedgerEntryRecord e, CancellationToken cancellationToken) =>
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO billing.ledger_entries (id, provider_id, kind, amount_paisa, booking_id, booking_number, job_total_paisa, rate_bp, created_at)
            VALUES ({e.Id}, {e.ProviderId}, {BillingKinds.Commission}, {e.AmountPaisa}, {e.BookingId}, {e.BookingNumber}, {e.JobTotalPaisa}, {e.RateBp}, {e.CreatedAt.ToUniversalTime()})
            ON CONFLICT ON CONSTRAINT ledger_entries_booking_kind_key DO NOTHING
            """, cancellationToken) == 1;

    /// <summary>Stores a new submission.</summary>
    public async Task AddSubmission(PaymentSubmissionRecord s, CancellationToken cancellationToken)
    {
        db.Add(s);
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
    }

    /// <summary>
    /// Moves a pending submission to `status`, so two admins cannot both review it; an unknown
    /// one is `billing.not_found`, a reviewed one `billing.not_pending`.
    /// </summary>
    public async Task<PaymentSubmissionRecord> Review(Guid id, string status, Guid reviewerId, string reason, DateTimeOffset at, CancellationToken cancellationToken)
    {
        var rows = await db.Set<PaymentSubmissionRecord>().FromSql($"""
            UPDATE billing.payment_submissions SET status = {status}, reviewer_id = {reviewerId}, reason = {reason}, reviewed_at = {at.ToUniversalTime()}
            WHERE id = {id} AND status = 'pending'
            RETURNING *
            """).AsNoTracking().ToListAsync(cancellationToken);
        if (rows.Count == 1)
        {
            return rows[0];
        }
        var exists = await db.Set<PaymentSubmissionRecord>().AnyAsync(s => s.Id == id, cancellationToken);
        throw new DomainException(exists ? BillingErrors.NotPending : BillingErrors.NotFound);
    }

    /// <summary>Credits a confirmed payment; one credit per submission.</summary>
    public Task AddCredit(PaymentSubmissionRecord s, Guid entryId, DateTimeOffset at, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO billing.ledger_entries (id, provider_id, kind, amount_paisa, submission_id, created_at)
        VALUES ({entryId}, {s.ProviderId}, {BillingKinds.Payment}, {s.AmountPaisa}, {s.Id}, {at.ToUniversalTime()})
        """, cancellationToken);

    /// <summary>Writes a Billing event for the merchant in the command's transaction.</summary>
    public Task Publish(Guid providerId, IDomainEvent domainEvent, CancellationToken cancellationToken) =>
        outbox.Write(db, Schemas.Billing, providerId.ToString(), domainEvent, cancellationToken);

    /// <summary>The merchant's ledger, newest first, strictly before (at, id).</summary>
    public Task<List<LedgerEntryRecord>> Ledger(Guid providerId, DateTimeOffset? beforeAt, Guid? beforeId, int limit, CancellationToken cancellationToken) =>
        db.Set<LedgerEntryRecord>().FromSql($"""
            SELECT * FROM billing.ledger_entries
            WHERE provider_id = {providerId}
              AND ({beforeAt}::timestamptz IS NULL OR (created_at, id) < ({beforeAt}::timestamptz, {beforeId ?? Guid.Empty}))
            ORDER BY created_at DESC, id DESC LIMIT {limit}
            """).AsNoTracking().ToListAsync(cancellationToken);

    /// <summary>Submissions of one merchant and/or one status (null means any), newest first, strictly before (at, id).</summary>
    public Task<List<PaymentSubmissionRecord>> Submissions(Guid? providerId, string? status, DateTimeOffset? beforeAt, Guid? beforeId, int limit, CancellationToken cancellationToken) =>
        db.Set<PaymentSubmissionRecord>().FromSql($"""
            SELECT * FROM billing.payment_submissions
            WHERE ({providerId}::uuid IS NULL OR provider_id = {providerId}::uuid)
              AND ({status}::text IS NULL OR status = {status}::text)
              AND ({beforeAt}::timestamptz IS NULL OR (created_at, id) < ({beforeAt}::timestamptz, {beforeId ?? Guid.Empty}))
            ORDER BY created_at DESC, id DESC LIMIT {limit}
            """).AsNoTracking().ToListAsync(cancellationToken);

    private sealed class TotalsRow
    {
        public long DebitPaisa { get; init; }

        public long CreditPaisa { get; init; }

        public long PendingPaisa { get; init; }
    }
}
