namespace PAO.Infrastructure.Data;

/// <summary>The injectable time source used instead of `DateTimeOffset.UtcNow` (01-conventions §4).</summary>
public interface IClock
{
    /// <summary>The current instant, in UTC.</summary>
    DateTimeOffset Now { get; }
}

/// <summary>The real clock.</summary>
public sealed class SystemClock : IClock
{
    /// <inheritdoc />
    public DateTimeOffset Now => DateTimeOffset.UtcNow;
}

/// <summary>Asia/Dhaka is UTC+6 without daylight saving; calendar boundaries use it (04-decisions E8).</summary>
public static class DhakaTime
{
    /// <summary>The fixed offset.</summary>
    public static readonly TimeSpan Offset = TimeSpan.FromHours(6);
}

/// <summary>Issues identifiers: UUIDv7 in production (04-decisions E3), scripted in tests.</summary>
public interface IIdGenerator
{
    /// <summary>A new id.</summary>
    Guid NewId();
}

/// <summary>Time-ordered UUIDv7 identifiers.</summary>
public sealed class UuidV7Generator : IIdGenerator
{
    /// <inheritdoc />
    public Guid NewId() => Guid.CreateVersion7();
}
