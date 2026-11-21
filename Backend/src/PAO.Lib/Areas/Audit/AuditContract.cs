using System.Text.Json.Nodes;

namespace PAO.Lib.Areas.Audit;

/// <summary>An append-only audit entry (PRD §6.4).</summary>
public sealed record AuditEntry
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The at.</summary>
    public required DateTimeOffset At { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
    /// <summary>The actor role.</summary>
    public required string ActorRole { get; init; }
    /// <summary>The action.</summary>
    public required string Action { get; init; }
    /// <summary>The subject type.</summary>
    public required string SubjectType { get; init; }
    /// <summary>The subject id.</summary>
    public required string SubjectId { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>The before.</summary>
    public JsonObject? Before { get; init; }
    /// <summary>The after.</summary>
    public JsonObject? After { get; init; }
}
