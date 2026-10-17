using System.Text.Json.Nodes;

namespace PAO.Lib.Areas.Audit;

/// <summary>An append-only audit entry (PRD §6.4).</summary>
public sealed record AuditEntry
{
    public required Guid Id { get; init; }
    public required DateTimeOffset At { get; init; }
    public Guid? ActorId { get; init; }
    public required string ActorRole { get; init; }
    public required string Action { get; init; }
    public required string SubjectType { get; init; }
    public required string SubjectId { get; init; }
    public required string Reason { get; init; }
    public JsonObject? Before { get; init; }
    public JsonObject? After { get; init; }
}
