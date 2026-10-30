namespace PAO.Core.Areas.Identity.Services;

/// <summary>A sent code as kept in Redis: only its hash and the attempts so far.</summary>
public sealed record StoredCode(string Hash, int Attempts);

/// <summary>
/// One signed-in device: a chain of refresh tokens where only the newest is valid.
/// Presenting an older one means the chain leaked, so the family is revoked.
/// </summary>
public sealed record Family
{
    /// <summary>The family (session) id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
    /// <summary>The app that signed in.</summary>
    public required string App { get; init; }
    /// <summary>The SHA-256 hex of the current refresh secret.</summary>
    public string CurrentHash { get; init; } = string.Empty;
    /// <summary>The live access token's id.</summary>
    public string AccessTokenId { get; init; } = string.Empty;
    /// <summary>When the live access token expires.</summary>
    public DateTimeOffset AccessExpiresAt { get; init; } = DateTimeOffset.UnixEpoch;
}

/// <summary>The pending second admin login step (`mfa:{id}`).</summary>
public sealed record Challenge
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The admin id.</summary>
    public required Guid AdminId { get; init; }
    /// <summary>Wrong codes so far.</summary>
    public int Attempts { get; init; }
    /// <summary>On the first login, the new secret the code must match; empty once enrolled.</summary>
    public string EnrolSecret { get; init; } = string.Empty;
}

/// <summary>Hashed one-time codes per purpose and phone; a missing code throws CodeExpired.</summary>
public interface ICodeStore
{
    /// <summary>Stores a code, replacing any earlier one.</summary>
    Task Save(string purpose, string phone, StoredCode code);
    /// <summary>Reads a code.</summary>
    Task<StoredCode> Get(string purpose, string phone);
    /// <summary>Counts a wrong guess.</summary>
    Task IncrementAttempts(string purpose, string phone);
    /// <summary>Drops a code.</summary>
    Task Delete(string purpose, string phone);
}

/// <summary>The send windows: resend timer, per phone and per client IP; zero when a send is allowed.</summary>
public interface ISendThrottle
{
    /// <summary>How long to wait before a code may be sent; `clientIp` null for server-side sends.</summary>
    Task<TimeSpan> RetryAfter(string phone, string? clientIp);
}

/// <summary>Refresh-token families (`rt:{id}`, indexed by `sess:{accountId}`); a missing one throws RefreshInvalid.</summary>
public interface ISessionStore
{
    /// <summary>Stores a family for `ttl`.</summary>
    Task Save(Family family, TimeSpan ttl);
    /// <summary>Reads a family.</summary>
    Task<Family> Get(Guid familyId);
    /// <summary>Drops a family.</summary>
    Task Delete(Family family);
    /// <summary>The account's live families.</summary>
    Task<IReadOnlyList<Family>> ListForAccount(Guid accountId);
}

/// <summary>Pending admin 2FA logins (`mfa:{id}`); a missing one throws ChallengeExpired.</summary>
public interface IChallengeStore
{
    /// <summary>Stores a challenge for `ttl`.</summary>
    Task Save(Challenge challenge, TimeSpan ttl);
    /// <summary>Reads a challenge.</summary>
    Task<Challenge> Get(Guid id);
    /// <summary>Drops a challenge.</summary>
    Task Delete(Guid id);
}
