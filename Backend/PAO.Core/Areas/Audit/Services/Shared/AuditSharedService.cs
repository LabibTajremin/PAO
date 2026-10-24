using PAO.Lib.Areas.Audit;

namespace PAO.Core.Areas.Audit.Services.Shared;

/// <summary>The Audit contract for the other areas.</summary>
public sealed class AuditSharedService(AuditLog log) : IAuditSharedService
{
    /// <summary>Appends `entry`; its id is ignored and a fresh one assigned.</summary>
    public Task Record(AuditEntry entry, CancellationToken cancellationToken) => log.Record(entry, null, cancellationToken);

    /// <inheritdoc />
    public Task<IReadOnlyList<AuditEntry>> ListForSubject(string subjectType, string subjectId, int limit, CancellationToken cancellationToken) =>
        log.List(new AuditFilter { SubjectType = subjectType, SubjectId = subjectId }, new AuditPage(limit), cancellationToken);
}
