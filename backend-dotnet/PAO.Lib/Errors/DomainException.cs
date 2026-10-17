namespace PAO.Lib.Errors;

/// <summary>
/// A business-rule failure raised by a handler or a shared service. `Reason` is a stable,
/// area-scoped key (for example `booking.not_found`); only the HTTP edge maps it to an API
/// error code (01-conventions §4).
/// </summary>
public sealed class DomainException : Exception
{
    /// <summary>Creates the failure for `reason`, optionally wrapping its cause.</summary>
    public DomainException(string reason, Exception? innerException = null)
        : base(reason, innerException)
    {
        Reason = reason;
    }

    /// <summary>The stable reason key.</summary>
    public string Reason { get; }

    /// <summary>Reports whether `error` is a <see cref="DomainException"/> with `reason`.</summary>
    public static bool Is(Exception? error, string reason) =>
        error is DomainException domain && domain.Reason == reason;
}
