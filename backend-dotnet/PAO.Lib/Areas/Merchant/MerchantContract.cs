using PAO.Lib.Common;

namespace PAO.Lib.Areas.Merchant;

/// <summary>Genders a merchant may declare (women-only services, PRD §5).</summary>
public static class Gender
{
    public const string Female = "female";
    public const string Male = "male";
    public const string Other = "other";
}

/// <summary>How nearby merchants are ordered after Level 2 (D11).</summary>
public static class SortOrder
{
    public const string Distance = "distance";
    public const string Rating = "rating";
}

/// <summary>The steps of the enrolment wizard.</summary>
public static class EnrolmentStep
{
    public const string Personal = "personal";
    public const string Services = "services";
    public const string Area = "area";
    public const string Nid = "nid";
    public const string Selfie = "selfie";
    public const string PoliceClearance = "police_clearance";
    public const string SkillProof = "skill_proof";
    public const string EmergencyContact = "emergency_contact";
    public const string CodeOfConduct = "code_of_conduct";
}

/// <summary>A merchant's emergency contact (PRD §6.2 item 6).</summary>
public sealed record EmergencyContact
{
    public required string Name { get; init; }
    public required string Relation { get; init; }
    public required string Phone { get; init; }
    public DateTimeOffset? VerifiedAt { get; init; }
}

/// <summary>A merchant (provider) profile.</summary>
public sealed record MerchantProfile
{
    public required Guid Id { get; init; }
    public required string FullName { get; init; }
    public DateOnly? DateOfBirth { get; init; }
    public required string Gender { get; init; }
    public required string PresentAddress { get; init; }
    public required string PermanentAddress { get; init; }
    public required string Phone { get; init; }
    public Guid? PhotoMediaId { get; init; }
    public required IReadOnlyList<Guid> ServiceIds { get; init; }
    public required int ExperienceYears { get; init; }
    public GeoPoint? HomeBase { get; init; }
    public required int WorkingRadiusM { get; init; }
    public required string Language { get; init; }
    public EmergencyContact? EmergencyContact { get; init; }
    public DateTimeOffset? SubmittedAt { get; init; }
}

/// <summary>Finds verified, online merchants for a service around a point.</summary>
public sealed record NearbyQuery
{
    public required Guid ServiceId { get; init; }
    public required GeoPoint Point { get; init; }
    public required int RadiusM { get; init; }
    public required bool WomenProvidersOnly { get; init; }
    public required string Sort { get; init; }
    public required int Limit { get; init; }
}

/// <summary>A search card for a nearby merchant.</summary>
public sealed record NearbyMerchant
{
    public required Guid ProviderId { get; init; }
    public required string Name { get; init; }
    public Guid? PhotoMediaId { get; init; }
    public required int Level { get; init; }
    public required double Rating { get; init; }
    public required int RatingCount { get; init; }
    public required int CompletedJobs { get; init; }
    public required double DistanceM { get; init; }
}

/// <summary>Progress of one enrolment step.</summary>
public sealed record StepStatus
{
    public required string Step { get; init; }
    public required bool Done { get; init; }
    public required bool Required { get; init; }
}

/// <summary>The wizard progress.</summary>
public sealed record EnrolmentStatus
{
    public required IReadOnlyList<StepStatus> Steps { get; init; }
    public required bool Complete { get; init; }
    public required bool Submitted { get; init; }
}

/// <summary>The Merchant area's error reasons; the `provider.` prefix is kept from NestJS.</summary>
public static class MerchantErrors
{
    public const string NotFound = "provider.not_found";
    public const string EnrolmentIncomplete = "provider.enrolment_incomplete";
}
