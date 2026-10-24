namespace PAO.Infrastructure.Http.Errors;

/// <summary>
/// An API error: the HTTP status, the stable `ErrorCode` the apps translate and a message
/// (PRD §9.6). Instances are immutable; <see cref="WithDetails"/> and <see cref="Wrap"/>
/// return copies.
/// </summary>
public sealed class ApiError : Exception
{
    /// <summary>Creates the error.</summary>
    public ApiError(int status, string code, string message, IReadOnlyDictionary<string, object?>? details = null, TimeSpan retryAfter = default, Exception? cause = null)
        : base(message, cause)
    {
        Status = status;
        Code = code;
        Details = details;
        RetryAfter = retryAfter;
    }

    /// <summary>The status.</summary>
    public int Status { get; }
    /// <summary>The code.</summary>
    public string Code { get; }
    /// <summary>The details.</summary>
    public IReadOnlyDictionary<string, object?>? Details { get; }

    /// <summary>For 429: how long the client should wait; sent as Retry-After in seconds.</summary>
    public TimeSpan RetryAfter { get; }

    /// <summary>A copy with `details` attached.</summary>
    public ApiError WithDetails(IReadOnlyDictionary<string, object?> details) =>
        new(Status, Code, Message, details, RetryAfter, InnerException);

    /// <summary>A copy that remembers the underlying error for logs.</summary>
    public ApiError Wrap(Exception cause) => new(Status, Code, Message, Details, RetryAfter, cause);
}

/// <summary>The errors the platform itself answers with; codes and messages match NestJS.</summary>
public static class ApiErrors
{
    /// <summary>No valid session; the app signs in again.</summary>
    public static readonly ApiError Unauthenticated = new(401, "UNAUTHENTICATED", "Sign in again.");

    /// <summary>The access token expired; the app refreshes it.</summary>
    public static readonly ApiError TokenExpired = new(401, "TOKEN_EXPIRED", "Session expired.");

    /// <summary>The caller lacks the permission.</summary>
    public static readonly ApiError Forbidden = new(403, "FORBIDDEN", "You do not have permission for this action.");

    /// <summary>Unknown route or resource.</summary>
    public static readonly ApiError NotFound = new(404, "NOT_FOUND", "Not found.");

    /// <summary>A known route called with the wrong method; the code stays NOT_FOUND as in the Go API.</summary>
    public static readonly ApiError MethodNotAllowed = new(405, "NOT_FOUND", "Method not allowed.");

    /// <summary>The request breaks the contract.</summary>
    public static readonly ApiError ValidationFailed = new(422, "VALIDATION_FAILED", "Invalid request.");

    /// <summary>Anything unexpected; the cause is logged, never sent.</summary>
    public static readonly ApiError Internal = new(500, "INTERNAL", "Something went wrong.");

    /// <summary>A spec operation no area serves yet.</summary>
    public static readonly ApiError NotImplemented = new(501, "NOT_IMPLEMENTED", "Not available yet.");

    /// <summary>The same Idempotency-Key with a different request.</summary>
    public static readonly ApiError IdempotencyKeyReused = new(422, "IDEMPOTENCY_KEY_REUSED", "This Idempotency-Key was used for a different request.");

    /// <summary>The first request with this Idempotency-Key has not finished.</summary>
    public static readonly ApiError IdempotencyInProgress = new(409, "CONFLICT", "The first request with this key is still running.");

    /// <summary>A 429 that tells the client when to retry.</summary>
    public static ApiError RateLimited(string code, TimeSpan retryAfter) =>
        new(429, code, "Too many requests. Try again later.", retryAfter: retryAfter);

    /// <summary>A 422 with one detail, e.g. `{reason: ...}`.</summary>
    public static ApiError Validation(string key, object? value) =>
        ValidationFailed.WithDetails(new Dictionary<string, object?> { [key] = value });
}

/// <summary>A stored answer to send again unchanged (idempotent replays).</summary>
public sealed class StoredResponseException(int status, byte[] body) : Exception("replay stored response")
{
    /// <summary>The status.</summary>
    public int Status { get; } = status;
    /// <summary>The body.</summary>
    public byte[] Body { get; } = body;
}
