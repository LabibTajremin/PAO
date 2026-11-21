using PAO.Core.Areas.Audit.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Audit.Services;

/// <summary>Why the audit log refused an entry.</summary>
public static class AuditReasons
{
    /// <summary>An entry needs an action and a subject.</summary>
    public const string Invalid = "audit.entry_invalid";

    /// <summary>Reports whether the entry names an action and a subject.</summary>
    public static bool IsComplete(string action, string subjectType, string subjectId) =>
        new[] { action, subjectType, subjectId }.All(s => s.Trim().Length > 0);
}

/// <summary>The append-only audit log (PRD §6.4, A-08).</summary>
public sealed class AuditLog(IAuditRepository repository, IClock clock, IIdGenerator ids)
{
    /// <summary>
    /// Appends an entry under a fresh id; a default `At` means now. `eventId` names the
    /// event it was written from, so a redelivered event adds nothing.
    /// </summary>
    public Task Record(AuditEntry entry, Guid? eventId, CancellationToken cancellationToken)
    {
        if (!AuditReasons.IsComplete(entry.Action, entry.SubjectType, entry.SubjectId))
        {
            throw new DomainException(AuditReasons.Invalid);
        }
        var stored = entry with { Id = ids.NewId(), At = entry.At == default ? clock.Now : entry.At };
        return repository.Append(stored, eventId, cancellationToken);
    }

    /// <summary>A page of entries, newest first.</summary>
    public Task<IReadOnlyList<AuditEntry>> List(AuditFilter filter, AuditPage page, CancellationToken cancellationToken) =>
        repository.List(filter, page, cancellationToken);
}
