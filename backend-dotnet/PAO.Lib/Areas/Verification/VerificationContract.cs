namespace PAO.Lib.Areas.Verification;

/// <summary>The verification items a merchant completes (PRD §6.1).</summary>
public static class ItemType
{
    public const string Nid = "nid";
    public const string Selfie = "selfie";
    public const string PoliceClearance = "police_clearance";
    public const string Address = "address";
    public const string EmergencyContact = "emergency_contact";
    public const string SkillProof = "skill_proof";
    public const string ServiceArea = "service_area";
    public const string CodeOfConduct = "code_of_conduct";
}

/// <summary>One verification item and its review state.</summary>
public sealed record VerificationItem
{
    public required string Type { get; init; }
    public required string Status { get; init; }
    public required string Reason { get; init; }
    public required bool Required { get; init; }
    public DateTimeOffset? DecidedAt { get; init; }
    public DateTimeOffset? ExpiresAt { get; init; }
}

/// <summary>The Verification area's error reasons.</summary>
public static class VerificationErrors
{
    public const string ProviderNotFound = "verification.provider_not_found";
}
