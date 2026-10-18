using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Audit;

/// <summary>Narrows the audit log (A-08); null fields do not filter.</summary>
public sealed record AuditFilter
{
    /// <summary>Who acted.</summary>
    public Guid? ActorId { get; init; }
    /// <summary>The action.</summary>
    public string? Action { get; init; }
    /// <summary>The subject type.</summary>
    public string? SubjectType { get; init; }
    /// <summary>The subject id.</summary>
    public string? SubjectId { get; init; }
    /// <summary>On or after.</summary>
    public DateTimeOffset? From { get; init; }
    /// <summary>On or before.</summary>
    public DateTimeOffset? To { get; init; }
}

/// <summary>A cursor position: entries strictly older than (At, Id), at most Limit of them.</summary>
public sealed record AuditPage(int Limit, DateTimeOffset? AfterAt = null, Guid? AfterId = null);

/// <summary>The spec's AuditEntry; empty role, reason and states are left out.</summary>
public sealed record AuditEntryView
{
    /// <summary>The id.</summary>
    public required string Id { get; init; }
    /// <summary>The at.</summary>
    public required string At { get; init; }
    /// <summary>The actor id.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ActorId { get; init; }
    /// <summary>The actor role.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ActorRole { get; init; }
    /// <summary>The action.</summary>
    public required string Action { get; init; }
    /// <summary>The subject type.</summary>
    public required string SubjectType { get; init; }
    /// <summary>The subject id.</summary>
    public required string SubjectId { get; init; }
    /// <summary>The reason.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Reason { get; init; }
    /// <summary>The before.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public JsonObject? Before { get; init; }
    /// <summary>The after.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public JsonObject? After { get; init; }
}

/// <summary>The spec's AuditList.</summary>
public sealed record AuditListView
{
    /// <summary>The items.</summary>
    public required IReadOnlyList<AuditEntryView> Items { get; init; }
    /// <summary>The next cursor, when more entries follow.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The Audit area's maps.</summary>
public sealed class AuditMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<AuditEntry, AuditEntryView>((e, _) => new AuditEntryView
        {
            Id = e.Id.ToString(),
            At = IsoTime.Format(e.At),
            ActorId = e.ActorId?.ToString(),
            ActorRole = e.ActorRole.Length == 0 ? null : e.ActorRole,
            Action = e.Action,
            SubjectType = e.SubjectType,
            SubjectId = e.SubjectId,
            Reason = e.Reason.Length == 0 ? null : e.Reason,
            Before = e.Before,
            After = e.After,
        });
}
