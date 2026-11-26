using PAO.Lib.Common;

namespace PAO.Lib.Areas.Merchant;

/// <summary>
/// The enrolment profile with the read-model copies of level, status and rating, as the
/// Merchant area keeps it. Saves write the profile fields only.
/// </summary>
public sealed record StoredMerchant
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The account phone.</summary>
    public string Phone { get; init; } = string.Empty;
    /// <summary>The name as on the NID.</summary>
    public string FullName { get; init; } = string.Empty;
    /// <summary>The Dhaka calendar date of birth.</summary>
    public DateOnly? DateOfBirth { get; init; }
    /// <summary>The gender; empty before the personal step.</summary>
    public string Gender { get; init; } = string.Empty;
    /// <summary>The present address.</summary>
    public string PresentAddress { get; init; } = string.Empty;
    /// <summary>The permanent address.</summary>
    public string PermanentAddress { get; init; } = string.Empty;
    /// <summary>The bio.</summary>
    public string Bio { get; init; } = string.Empty;
    /// <summary>The avatar upload.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>Years of experience.</summary>
    public int ExperienceYears { get; init; }
    /// <summary>The language.</summary>
    public string Language { get; init; } = Common.Language.Bangla;
    /// <summary>The services offered.</summary>
    public IReadOnlyList<Guid> ServiceIds { get; init; } = [];
    /// <summary>The home base.</summary>
    public GeoPoint? HomeBase { get; init; }
    /// <summary>The working radius in metres.</summary>
    public int WorkingRadiusM { get; init; }
    /// <summary>The guarantor; empty fields before the step.</summary>
    public EmergencyContact Emergency { get; init; } = new() { Name = string.Empty, Relation = string.Empty, Phone = string.Empty };
    /// <summary>The accepted code-of-conduct version.</summary>
    public string CocVersion { get; init; } = string.Empty;
    /// <summary>When it was accepted.</summary>
    public DateTimeOffset? CocAcceptedAt { get; init; }
    /// <summary>The wizard steps done.</summary>
    public IReadOnlyList<string> StepsDone { get; init; } = [];
    /// <summary>When the enrolment went to review.</summary>
    public DateTimeOffset? SubmittedAt { get; init; }
    /// <summary>The account status copy.</summary>
    public string AccountStatus { get; init; } = "active";
    /// <summary>The verification level copy.</summary>
    public int Level { get; init; }
    /// <summary>The rating average copy.</summary>
    public double RatingAvg { get; init; }
    /// <summary>The rating count copy.</summary>
    public int RatingCount { get; init; }
    /// <summary>Completed jobs.</summary>
    public int CompletedJobs { get; init; }
    /// <summary>Whether a quality threshold flagged them.</summary>
    public bool Flagged { get; init; }
    /// <summary>Why they were flagged.</summary>
    public string FlagReason { get; init; } = string.Empty;
    /// <summary>When the profile was created.</summary>
    public DateTimeOffset CreatedAt { get; init; }
}

/// <summary>A merchant found near a customer, before ranking.</summary>
public sealed record MerchantCandidate
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The full name.</summary>
    public required string Name { get; init; }
    /// <summary>The avatar upload.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>The gender.</summary>
    public required string Gender { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The rating average.</summary>
    public required double Rating { get; init; }
    /// <summary>The rating count.</summary>
    public required int RatingCount { get; init; }
    /// <summary>Completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>Metres from the customer.</summary>
    public required double DistanceM { get; init; }
    /// <summary>The merchant's own working radius.</summary>
    public required int WorkingRadiusM { get; init; }
}

/// <summary>A catalog service as the Merchant area uses it: Level 2 services raise the minimum level.</summary>
public sealed record MerchantService
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>Whether customers can book it.</summary>
    public required bool Published { get; init; }
    /// <summary>The minimum merchant level.</summary>
    public required int MinLevel { get; init; }
    /// <summary>Whether only women may take it (D11).</summary>
    public required bool WomenProvidersOnly { get; init; }
}
