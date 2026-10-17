using PAO.Lib.Common;

namespace PAO.Lib.Areas.Merchant;

/// <summary>Genders a merchant may declare (women-only services, PRD §5).</summary>
public static class Gender
{
    /// <summary>The `"female"` value.</summary>
    public const string Female = "female";
    /// <summary>The `"male"` value.</summary>
    public const string Male = "male";
    /// <summary>The `"other"` value.</summary>
    public const string Other = "other";
}

/// <summary>How nearby merchants are ordered after Level 2 (D11).</summary>
public static class SortOrder
{
    /// <summary>The `"distance"` value.</summary>
    public const string Distance = "distance";
    /// <summary>The `"rating"` value.</summary>
    public const string Rating = "rating";
}

/// <summary>The steps of the enrolment wizard.</summary>
public static class EnrolmentStep
{
    /// <summary>The `"personal"` value.</summary>
    public const string Personal = "personal";
    /// <summary>The `"services"` value.</summary>
    public const string Services = "services";
    /// <summary>The `"area"` value.</summary>
    public const string Area = "area";
    /// <summary>The `"nid"` value.</summary>
    public const string Nid = "nid";
    /// <summary>The `"selfie"` value.</summary>
    public const string Selfie = "selfie";
    /// <summary>The `"police_clearance"` value.</summary>
    public const string PoliceClearance = "police_clearance";
    /// <summary>The `"skill_proof"` value.</summary>
    public const string SkillProof = "skill_proof";
    /// <summary>The `"emergency_contact"` value.</summary>
    public const string EmergencyContact = "emergency_contact";
    /// <summary>The `"code_of_conduct"` value.</summary>
    public const string CodeOfConduct = "code_of_conduct";
}

/// <summary>A merchant's emergency contact (PRD §6.2 item 6).</summary>
public sealed record EmergencyContact
{
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The relation.</summary>
    public required string Relation { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The verified at.</summary>
    public DateTimeOffset? VerifiedAt { get; init; }
}

/// <summary>A merchant (provider) profile.</summary>
public sealed record MerchantProfile
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The full name.</summary>
    public required string FullName { get; init; }
    /// <summary>The date of birth.</summary>
    public DateOnly? DateOfBirth { get; init; }
    /// <summary>The gender.</summary>
    public required string Gender { get; init; }
    /// <summary>The present address.</summary>
    public required string PresentAddress { get; init; }
    /// <summary>The permanent address.</summary>
    public required string PermanentAddress { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The photo media id.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>The service ids.</summary>
    public required IReadOnlyList<Guid> ServiceIds { get; init; }
    /// <summary>The experience years.</summary>
    public required int ExperienceYears { get; init; }
    /// <summary>The home base.</summary>
    public GeoPoint? HomeBase { get; init; }
    /// <summary>The working radius m.</summary>
    public required int WorkingRadiusM { get; init; }
    /// <summary>The language.</summary>
    public required string Language { get; init; }
    /// <summary>The emergency contact.</summary>
    public EmergencyContact? EmergencyContact { get; init; }
    /// <summary>The submitted at.</summary>
    public DateTimeOffset? SubmittedAt { get; init; }
}

/// <summary>Finds verified, online merchants for a service around a point.</summary>
public sealed record NearbyQuery
{
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The point.</summary>
    public required GeoPoint Point { get; init; }
    /// <summary>The radius m.</summary>
    public required int RadiusM { get; init; }
    /// <summary>Whether women providers only.</summary>
    public required bool WomenProvidersOnly { get; init; }
    /// <summary>The sort.</summary>
    public required string Sort { get; init; }
    /// <summary>The limit.</summary>
    public required int Limit { get; init; }
}

/// <summary>A search card for a nearby merchant.</summary>
public sealed record NearbyMerchant
{
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The photo media id.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The rating.</summary>
    public required double Rating { get; init; }
    /// <summary>The rating count.</summary>
    public required int RatingCount { get; init; }
    /// <summary>The completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>The distance m.</summary>
    public required double DistanceM { get; init; }
}

/// <summary>Progress of one enrolment step.</summary>
public sealed record StepStatus
{
    /// <summary>The step.</summary>
    public required string Step { get; init; }
    /// <summary>Whether done.</summary>
    public required bool Done { get; init; }
    /// <summary>Whether required.</summary>
    public required bool Required { get; init; }
}

/// <summary>The wizard progress.</summary>
public sealed record EnrolmentStatus
{
    /// <summary>The steps.</summary>
    public required IReadOnlyList<StepStatus> Steps { get; init; }
    /// <summary>Whether complete.</summary>
    public required bool Complete { get; init; }
    /// <summary>Whether submitted.</summary>
    public required bool Submitted { get; init; }
}

/// <summary>The Merchant area's error reasons; the `provider.` prefix is kept from NestJS.</summary>
public static class MerchantErrors
{
    /// <summary>The `"provider.not_found"` value.</summary>
    public const string NotFound = "provider.not_found";
    /// <summary>The `"provider.enrolment_incomplete"` value.</summary>
    public const string EnrolmentIncomplete = "provider.enrolment_incomplete";
}
