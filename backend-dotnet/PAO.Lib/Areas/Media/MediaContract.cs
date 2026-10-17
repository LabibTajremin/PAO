namespace PAO.Lib.Areas.Media;

/// <summary>What an upload is for; each purpose has its own type and size rules.</summary>
public static class MediaPurpose
{
    public const string Avatar = "avatar";
    public const string NidFront = "nid_front";
    public const string NidBack = "nid_back";
    public const string Selfie = "selfie";
    public const string PoliceClearance = "police_clearance";
    public const string SkillProof = "skill_proof";
    public const string AddressProof = "address_proof";
    public const string ComplaintPhoto = "complaint_photo";
    public const string Level2Photo = "level2_photo";
}

/// <summary>Asks for a presigned upload.</summary>
public sealed record UploadRequest
{
    public required Guid OwnerId { get; init; }
    public required string Purpose { get; init; }
    public required string ContentType { get; init; }
    public required long SizeBytes { get; init; }
}

/// <summary>A presigned PUT and the headers the client must send with it.</summary>
public sealed record UploadTicket
{
    public required Guid MediaId { get; init; }
    public required string Url { get; init; }
    public required IReadOnlyDictionary<string, string> Headers { get; init; }
    public required DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>An uploaded object's metadata.</summary>
public sealed record MediaObject
{
    public required Guid Id { get; init; }
    public required Guid OwnerId { get; init; }
    public required string Purpose { get; init; }
    public required string ContentType { get; init; }
    public required long SizeBytes { get; init; }
    public required bool Confirmed { get; init; }
}

/// <summary>Asks for a signed view URL; document views are audited (PRD §6.6).</summary>
public sealed record ViewRequest
{
    public required Guid MediaId { get; init; }
    public required Guid ViewerId { get; init; }
    public required string ViewerRole { get; init; }
}

/// <summary>A signed GET URL and when it stops working.</summary>
public sealed record ViewUrl
{
    public required string Url { get; init; }
    public required DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>The Media area's error reasons.</summary>
public static class MediaErrors
{
    public const string UploadInvalid = "media.upload_invalid";
    public const string NotFound = "media.not_found";
    public const string NotUploaded = "media.not_uploaded";
}
