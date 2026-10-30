using PAO.Lib.Areas.Audit;

namespace PAO.Core.Areas.Audit.Services.Shared;

/// <summary>
/// What other areas may ask of the Audit area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IAuditSharedService
{
    /// <summary>Appends an entry; entries can never be edited or deleted (PRD §6.4).</summary>
    Task Record(AuditEntry entry, CancellationToken cancellationToken);

    /// <summary>Returns the newest entries about one subject, e.g. a merchant's status history.</summary>
    Task<IReadOnlyList<AuditEntry>> ListForSubject(string subjectType, string subjectId, int limit, CancellationToken cancellationToken);
}
