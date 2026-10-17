namespace PAO.Lib.Areas.Verification;

/// <summary>The verification items a merchant completes (PRD §6.1).</summary>
public static class ItemType
{
    /// <summary>The `"nid"` value.</summary>
    public const string Nid = "nid";
    /// <summary>The `"selfie"` value.</summary>
    public const string Selfie = "selfie";
    /// <summary>The `"police_clearance"` value.</summary>
    public const string PoliceClearance = "police_clearance";
    /// <summary>The `"address"` value.</summary>
    public const string Address = "address";
    /// <summary>The `"emergency_contact"` value.</summary>
    public const string EmergencyContact = "emergency_contact";
    /// <summary>The `"skill_proof"` value.</summary>
    public const string SkillProof = "skill_proof";
    /// <summary>The `"service_area"` value.</summary>
    public const string ServiceArea = "service_area";
    /// <summary>The `"code_of_conduct"` value.</summary>
    public const string CodeOfConduct = "code_of_conduct";
}

/// <summary>One verification item and its review state.</summary>
public sealed record VerificationItem
{
    /// <summary>The type.</summary>
    public required string Type { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>Whether required.</summary>
    public required bool Required { get; init; }
    /// <summary>The decided at.</summary>
    public DateTimeOffset? DecidedAt { get; init; }
    /// <summary>The expires at.</summary>
    public DateTimeOffset? ExpiresAt { get; init; }
}

/// <summary>The Verification area's error reasons.</summary>
public static class VerificationErrors
{
    /// <summary>The `"verification.provider_not_found"` value.</summary>
    public const string ProviderNotFound = "verification.provider_not_found";
}
