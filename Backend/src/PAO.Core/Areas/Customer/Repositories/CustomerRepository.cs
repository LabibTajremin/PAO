using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Customer;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Customer.Repositories;

/// <summary>A profile as stored, with the identity copies the admin list shows (A-05).</summary>
public sealed record StoredCustomer(Guid Id, string Name, Guid? PhotoMediaId, string Language, DateTimeOffset At, string Phone, string Status);

/// <summary>Stores customer profiles (`customer.customers`) and their admin list copies.</summary>
public sealed class CustomerRepository(PaoDbContext db, OutboxWriter outbox, IMapper mapper)
{
    /// <summary>Creates or updates the profile and stores `saved` in the outbox, in the caller's transaction.</summary>
    public async Task Save(StoredCustomer c, CustomerProfileSaved saved, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO customer.customers (id, name, photo_media_id, language, created_at, updated_at, phone, account_status)
            VALUES ({c.Id}, {c.Name}, {c.PhotoMediaId}, {c.Language}, {c.At}, {c.At}, {c.Phone}, {c.Status})
            ON CONFLICT (id) DO UPDATE SET name = excluded.name, photo_media_id = excluded.photo_media_id,
                language = excluded.language, updated_at = excluded.updated_at, phone = excluded.phone,
                account_status = excluded.account_status
            """, cancellationToken);
        await outbox.Write(db, Schemas.Customer, c.Id.ToString(), saved, cancellationToken);
    }

    /// <summary>The stored profile; `customer.not_found` without one.</summary>
    public async Task<CustomerProfile> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<CustomerProfileRecord>().FirstOrDefaultAsync(c => c.Id == id, cancellationToken)
            ?? throw new DomainException(CustomerErrors.NotFound);
        return mapper.Map<CustomerProfileRecord, CustomerProfile>(row);
    }

    /// <summary>Customers for the admin console, newest first, continuing after (`AfterAt`, `AfterId`).</summary>
    public async Task<IReadOnlyList<CustomerRecord>> Search(CustomerQuery q, CancellationToken cancellationToken)
    {
        var pattern = SqlLike.Contains(q.Text);
        string? status = q.Status.Length == 0 ? null : q.Status;
        var afterId = q.AfterId ?? Guid.Empty;
        var afterAt = q.AfterAt?.ToUniversalTime();
        var rows = await db.Set<CustomerProfileRecord>().FromSql($"""
            SELECT * FROM customer.customers
            WHERE ({q.Id}::uuid IS NULL OR id = {q.Id}::uuid)
              AND ({pattern} = '' OR lower(name) LIKE {pattern} OR phone LIKE {pattern})
              AND ({status}::text IS NULL OR account_status = {status}::text)
              AND ({afterAt}::timestamptz IS NULL OR (created_at, id) < ({afterAt}::timestamptz, {afterId}))
            ORDER BY created_at DESC, id DESC
            LIMIT {q.Limit}
            """).ToListAsync(cancellationToken);
        return mapper.MapAll<CustomerProfileRecord, CustomerRecord>(rows);
    }

    /// <summary>Erases a customer and, by cascade, their addresses (account deletion, PRD §11).</summary>
    public static Task Erase(PaoDbContext context, Guid id, CancellationToken cancellationToken) =>
        context.Set<CustomerProfileRecord>().Where(c => c.Id == id).ExecuteDeleteAsync(cancellationToken);

    /// <summary>Copies a new account status for the admin list.</summary>
    public static Task SetStatus(PaoDbContext context, Guid id, string status, CancellationToken cancellationToken) =>
        context.Set<CustomerProfileRecord>().Where(c => c.Id == id)
            .ExecuteUpdateAsync(u => u.SetProperty(c => c.AccountStatus, status), cancellationToken);

    /// <summary>Counts one more booking for the admin list.</summary>
    public static Task CountBooking(PaoDbContext context, Guid id, CancellationToken cancellationToken) =>
        context.Set<CustomerProfileRecord>().Where(c => c.Id == id)
            .ExecuteUpdateAsync(u => u.SetProperty(c => c.Bookings, c => c.Bookings + 1), cancellationToken);
}
