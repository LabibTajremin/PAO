namespace PAO.Lib.Areas.Media;

/// <summary>What an upload is for; each purpose has its own type and size rules.</summary>
public static class MediaPurpose
{
    /// <summary>The `"avatar"` value.</summary>
    public const string Avatar = "avatar";
    /// <summary>The `"nid_front"` value.</summary>
    public const string NidFront = "nid_front";
    /// <summary>The `"nid_back"` value.</summary>
    public const string NidBack = "nid_back";
    /// <summary>The `"selfie"` value.</summary>
    public const string Selfie = "selfie";
    /// <summary>The `"police_clearance"` value.</summary>
    public const string PoliceClearance = "police_clearance";
    /// <summary>The `"skill_proof"` value.</summary>
    public const string SkillProof = "skill_proof";
    /// <summary>The `"address_proof"` value.</summary>
    public const string AddressProof = "address_proof";
    /// <summary>The `"complaint_photo"` value.</summary>
    public const string ComplaintPhoto = "complaint_photo";
    /// <summary>The `"level2_photo"` value.</summary>
    public const string Level2Photo = "level2_photo";
}

/// <summary>Asks for a presigned upload.</summary>
public sealed record UploadRequest
{
    /// <summary>The owner id.</summary>
    public required Guid OwnerId { get; init; }
    /// <summary>The purpose.</summary>
    public required string Purpose { get; init; }
    /// <summary>The content type.</summary>
    public required string ContentType { get; init; }
    /// <summary>The size bytes.</summary>
    public required long SizeBytes { get; init; }
}

/// <summary>A presigned PUT and the headers the client must send with it.</summary>
public sealed record UploadTicket
{
    /// <summary>The media id.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>The URL.</summary>
    public required string Url { get; init; }
    /// <summary>The headers.</summary>
    public required IReadOnlyDictionary<string, string> Headers { get; init; }
    /// <summary>The expires at.</summary>
    public required DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>An uploaded object's metadata.</summary>
public sealed record MediaObject
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The owner id.</summary>
    public required Guid OwnerId { get; init; }
    /// <summary>The purpose.</summary>
    public required string Purpose { get; init; }
    /// <summary>The content type.</summary>
    public required string ContentType { get; init; }
    /// <summary>The size bytes.</summary>
    public required long SizeBytes { get; init; }
    /// <summary>Whether confirmed.</summary>
    public required bool Confirmed { get; init; }
}

/// <summary>Asks for a signed view URL; document views are audited (PRD §6.6).</summary>
public sealed record ViewRequest
{
    /// <summary>The media id.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>The viewer id.</summary>
    public required Guid ViewerId { get; init; }
    /// <summary>The viewer role.</summary>
    public required string ViewerRole { get; init; }
}

/// <summary>A signed GET URL and when it stops working.</summary>
public sealed record ViewUrl
{
    /// <summary>The URL.</summary>
    public required string Url { get; init; }
    /// <summary>The expires at.</summary>
    public required DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>The Media area's error reasons.</summary>
public static class MediaErrors
{
    /// <summary>The `"media.upload_invalid"` value.</summary>
    public const string UploadInvalid = "media.upload_invalid";
    /// <summary>The `"media.not_found"` value.</summary>
    public const string NotFound = "media.not_found";
    /// <summary>The `"media.not_uploaded"` value.</summary>
    public const string NotUploaded = "media.not_uploaded";
}
