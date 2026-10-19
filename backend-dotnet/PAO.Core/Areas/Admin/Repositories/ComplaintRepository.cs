using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Admin;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Admin.Repositories;

/// <summary>Complaints and their support notes (C-14, A-07); writes join the command's transaction with their events.</summary>
public sealed class ComplaintRepository(PaoDbContext db, OutboxWriter outbox)
{
    /// <summary>Stores the complaint with the next ticket number and the event built from the stored complaint.</summary>
    public async Task<Complaint> Create(ComplaintRecord row, Func<Complaint, IDomainEvent> domainEvent, CancellationToken cancellationToken)
    {
        db.Add(row);
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
        var stored = new Complaint(row, []);
        await outbox.Write(db, Schemas.Admin, row.Id.ToString(), domainEvent(stored), cancellationToken);
        return stored;
    }

    /// <summary>The complaint with its notes; `admin.complaint_not_found` without one.</summary>
    public async Task<Complaint> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<ComplaintRecord>().AsNoTracking().FirstOrDefaultAsync(c => c.Id == id, cancellationToken)
            ?? throw new DomainException(AdminReasons.ComplaintNotFound);
        var comments = await db.Set<ComplaintCommentRecord>().AsNoTracking().Where(c => c.ComplaintId == id)
            .OrderBy(c => c.At).ThenBy(c => c.Id).ToListAsync(cancellationToken);
        return new Complaint(row, [.. comments.Select(c => new ComplaintComment(c.Id, c.ComplaintId, c.AuthorId, c.Body, c.At))]);
    }

    /// <summary>A page of the queue, newest first; list rows carry no notes.</summary>
    public async Task<IReadOnlyList<Complaint>> List(ComplaintFilter f, CancellationToken cancellationToken)
    {
        var rows = await db.Set<ComplaintRecord>().FromSql($"""
            SELECT * FROM admin.complaints
            WHERE ({f.Status}::text IS NULL OR status = {f.Status}::text)
              AND ({f.AssigneeId}::uuid IS NULL OR assignee_id = {f.AssigneeId}::uuid)
              AND ({f.AfterAt}::timestamptz IS NULL OR (created_at, id) < ({f.AfterAt}::timestamptz, {f.AfterId ?? Guid.Empty}))
            ORDER BY created_at DESC, id DESC LIMIT {f.Limit}
            """).AsNoTracking().ToListAsync(cancellationToken);
        return [.. rows.Select(r => new Complaint(r, []))];
    }

    /// <summary>Applies `change` to the locked row and writes the event it returns, if any.</summary>
    public async Task Save(Guid id, Func<ComplaintRecord, IDomainEvent?> change, CancellationToken cancellationToken)
    {
        var row = (await db.Set<ComplaintRecord>().FromSql($"SELECT * FROM admin.complaints WHERE id = {id} FOR UPDATE").AsTracking().ToListAsync(cancellationToken))
            .FirstOrDefault() ?? throw new DomainException(AdminReasons.ComplaintNotFound);
        var e = change(row);
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
        if (e is not null)
        {
            await outbox.Write(db, Schemas.Admin, id.ToString(), e, cancellationToken);
        }
    }

    /// <summary>Adds a support note.</summary>
    public async Task AddComment(ComplaintCommentRecord comment, CancellationToken cancellationToken)
    {
        db.Add(comment);
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
    }

    /// <summary>Verified complaints against a person (PRD §6.4).</summary>
    public Task<int> CountVerified(Guid againstId, CancellationToken cancellationToken) =>
        db.Set<ComplaintRecord>().CountAsync(c => c.AgainstId == againstId && c.Verified, cancellationToken);

    /// <summary>Every complaint against a person.</summary>
    public Task<int> CountAgainst(Guid againstId, CancellationToken cancellationToken) =>
        db.Set<ComplaintRecord>().CountAsync(c => c.AgainstId == againstId, cancellationToken);

    /// <summary>Unresolved complaints.</summary>
    public Task<int> CountOpen(CancellationToken cancellationToken) =>
        db.Set<ComplaintRecord>().CountAsync(c => c.Status != "resolved", cancellationToken);

    /// <summary>The newest complaints a person reported or received.</summary>
    public async Task<IReadOnlyList<Complaint>> Involving(Guid id, int limit, CancellationToken cancellationToken)
    {
        var rows = await db.Set<ComplaintRecord>().AsNoTracking().Where(c => c.ReporterId == id || c.AgainstId == id)
            .OrderByDescending(c => c.CreatedAt).ThenByDescending(c => c.Id).Take(limit).ToListAsync(cancellationToken);
        return [.. rows.Select(r => new Complaint(r, []))];
    }
}
