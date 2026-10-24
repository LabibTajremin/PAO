using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Lib.Areas.Merchant;

/// <summary>The `PersonalInfoInput` body (M05).</summary>
public sealed record PersonalInfoInput
{
    /// <summary>The name as on the NID.</summary>
    public string FullName { get; init; } = string.Empty;
    /// <summary>The date of birth.</summary>
    public DateOnly DateOfBirth { get; init; }
    /// <summary>`female`, `male` or `other`.</summary>
    public string Gender { get; init; } = string.Empty;
    /// <summary>The present address.</summary>
    public string PresentAddress { get; init; } = string.Empty;
    /// <summary>The permanent address.</summary>
    public string PermanentAddress { get; init; } = string.Empty;
    /// <summary>The bio; empty when missing.</summary>
    public string? Bio { get; init; }
}

/// <summary>The `ServicesInput` body (M06).</summary>
public sealed record ServicesInput
{
    /// <summary>One to five catalog services.</summary>
    public IReadOnlyList<Guid> ServiceIds { get; init; } = [];
    /// <summary>Years of experience.</summary>
    public int ExperienceYears { get; init; }
}

/// <summary>The `ServiceAreaInput` body (M07).</summary>
public sealed record ServiceAreaInput
{
    /// <summary>Where the merchant works from.</summary>
    public GeoPoint HomeBase { get; init; } = new() { Lat = 0, Lng = 0 };
    /// <summary>How far they travel, in metres.</summary>
    public int WorkingRadiusM { get; init; }
}

/// <summary>The `EmergencyContactInput` body (M12).</summary>
public sealed record EmergencyContactInput
{
    /// <summary>The guarantor's name.</summary>
    public string Name { get; init; } = string.Empty;
    /// <summary>How they are related.</summary>
    public string Relation { get; init; } = string.Empty;
    /// <summary>Their mobile number, in any common spelling.</summary>
    public string Phone { get; init; } = string.Empty;
}

/// <summary>The `EmergencyContactVerifyInput` body.</summary>
public sealed record EmergencyContactVerifyInput
{
    /// <summary>The six-digit code the guarantor received.</summary>
    public string Code { get; init; } = string.Empty;
}

/// <summary>The `CodeOfConductInput` body (M13).</summary>
public sealed record CodeOfConductInput
{
    /// <summary>The version the merchant read.</summary>
    public string Version { get; init; } = string.Empty;
    /// <summary>Must be true.</summary>
    public bool Accepted { get; init; }
}

/// <summary>The `ProviderProfileUpdate` body (M28).</summary>
public sealed record MerchantProfileInput
{
    /// <summary>The bio; empty when missing.</summary>
    public string? Bio { get; init; }
    /// <summary>A confirmed avatar upload of the merchant.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>`en` or `bn`.</summary>
    public string Language { get; init; } = string.Empty;
}

/// <summary>The `HeartbeatInput` body.</summary>
public sealed record HeartbeatInput
{
    /// <summary>Where the merchant is now.</summary>
    public GeoPoint Location { get; init; } = new() { Lat = 0, Lng = 0 };
}

/// <summary>Why the Merchant area refused something; the `provider.` prefix is kept from NestJS.</summary>
public static class MerchantReasons
{
    /// <summary>The fields break the rules.</summary>
    public const string Invalid = "provider.invalid";
    /// <summary>The merchant is not 18 yet.</summary>
    public const string TooYoung = "provider.too_young";
    /// <summary>A service is unknown or unpublished.</summary>
    public const string UnknownService = "provider.unknown_service";
    /// <summary>Only active, verified merchants may go online.</summary>
    public const string NotVerified = "provider.not_verified";
    /// <summary>Services and area must be chosen first.</summary>
    public const string NoServiceArea = "provider.no_service_area";
    /// <summary>The merchant is not online.</summary>
    public const string Offline = "provider.offline";
    /// <summary>There is no emergency contact to verify.</summary>
    public const string ContactUnproven = "provider.contact_unproven";
    /// <summary>The guarantor's code is wrong, expired or locked.</summary>
    public const string CodeRejected = "provider.code_rejected";
    /// <summary>Too many codes were sent.</summary>
    public const string CodeRateLimited = "provider.code_rate_limited";
    /// <summary>The photo is not a confirmed avatar upload of this merchant.</summary>
    public const string InvalidPhoto = "provider.invalid_photo";
}

/// <summary>
/// Takes merchants whose heartbeat lapsed offline with `ProviderWentOffline{reason:
/// heartbeat_lost}`; here so the worker's job can send it without referencing the API.
/// </summary>
public sealed record ReapLostPresence : ICommand;
