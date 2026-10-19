using System.Globalization;
using System.Text.Json;
using PAO.EF.Verification;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Verification;

/// <summary>The Verification area's maps: rows to domain records, domain records to views.</summary>
public sealed class VerificationMappingProfile : IMappingProfile
{
    /// <summary>JSON columns (`fields`, `checklist`) in the camelCase NestJS wrote.</summary>
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>The ISO 8601 form the API uses for times (milliseconds, UTC), as `toISOString` wrote them.</summary>
    public static string Iso(DateTimeOffset at) => at.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);

    /// <summary>`Iso` for an optional time.</summary>
    public static string? Iso(DateTimeOffset? at) => at is { } value ? Iso(value) : null;

    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<VerificationItemRecord, ItemState>((r, _) => Item(r))
        .Add<Level2SessionRecord, Level2SessionState>((r, _) => SessionState(r))
        .Add<VerificationDocumentRecord, VerificationDocument>((r, _) => new VerificationDocument
        {
            Id = r.Id,
            ItemType = r.ItemType,
            Kind = r.Kind,
            MediaId = r.MediaId,
            CreatedAt = r.CreatedAt,
        })
        .Add<ItemState, VerificationItemView>((it, _) => new VerificationItemView
        {
            Type = it.Type,
            Status = it.Status,
            Required = ItemType.IsRequired(it.Type),
            RejectionReason = it.Reason.Length == 0 ? null : it.Reason,
            DecidedAt = Iso(it.DecidedAt),
            ExpiresAt = Iso(it.ExpiresAt),
        })
        .Add<Level2SessionState, Level2SessionView>((s, _) => Session(s))
        .Add<EnrolmentStatus, EnrolmentStatusView>((e, _) => new EnrolmentStatusView
        {
            Steps = [.. e.Steps.Select(s => new StepStatusView { Step = s.Step, Done = s.Done, Required = s.Required })],
            Complete = e.Complete,
            Submitted = e.Submitted,
        });

    private static Level2SessionView Session(Level2SessionState s)
    {
        var done = s.Result.Length > 0;
        return new Level2SessionView
        {
            Id = s.Id,
            ProviderId = s.ProviderId,
            ServiceId = s.ServiceId,
            ScheduledAt = Iso(s.ScheduledAt),
            Location = s.Location,
            Status = s.Status,
            DecidedBy = s.DecidedBy,
            Result = done ? s.Result : null,
            Notes = done ? s.Notes : null,
            Checklist = done ? s.Checklist : null,
        };
    }

    private static ItemState Item(VerificationItemRecord r) => new()
    {
        Type = r.ItemType,
        Status = r.Status,
        Reason = r.RejectionReason,
        Fields = JsonSerializer.Deserialize<Dictionary<string, string>>(r.Fields, Json)!,
        SubmittedAt = r.SubmittedAt,
        DecidedAt = r.DecidedAt,
        DecidedBy = r.DecidedBy,
        ExpiresAt = r.ExpiresAt,
    };

    private static Level2SessionState SessionState(Level2SessionRecord r) => new()
    {
        Id = r.Id,
        ProviderId = r.ProviderId,
        ServiceId = r.ServiceId,
        ScheduledAt = r.ScheduledAt,
        Location = r.Location,
        Status = r.Status,
        Result = r.Result ?? string.Empty,
        Checklist = JsonSerializer.Deserialize<List<CheckItem>>(r.Checklist, Json)!,
        Notes = r.Notes,
        VisitLat = r.VisitLat,
        VisitLng = r.VisitLng,
        Photos = r.PhotoMediaIds,
        DecidedBy = r.DecidedBy,
        DecidedAt = r.DecidedAt,
        CreatedAt = r.CreatedAt,
    };
}
