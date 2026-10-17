namespace PAO.Infrastructure.Http.Filters;

/// <summary>A write-only stream that writes to `inner` and keeps a copy in `copy`.</summary>
public sealed class TeeStream(Stream inner, Stream copy) : Stream
{
    /// <summary>Whether can read.</summary>
    public override bool CanRead => false;
    /// <summary>Whether can seek.</summary>
    public override bool CanSeek => false;
    /// <summary>Whether can write.</summary>
    public override bool CanWrite => true;
    /// <summary>The length.</summary>
    public override long Length => throw new NotSupportedException();

    /// <summary>The position.</summary>
    public override long Position
    {
        get => throw new NotSupportedException();
        set => throw new NotSupportedException();
    }

    /// <inheritdoc />
    public override void Write(byte[] buffer, int offset, int count)
    {
        copy.Write(buffer, offset, count);
        inner.Write(buffer, offset, count);
    }

    /// <inheritdoc />
    public override async ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
    {
        copy.Write(buffer.Span);
        await inner.WriteAsync(buffer, cancellationToken);
    }

    /// <inheritdoc />
    public override Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken) =>
        WriteAsync(buffer.AsMemory(offset, count), cancellationToken).AsTask();

    /// <inheritdoc />
    public override void Flush() => inner.Flush();

    /// <inheritdoc />
    public override Task FlushAsync(CancellationToken cancellationToken) => inner.FlushAsync(cancellationToken);

    /// <inheritdoc />
    public override int Read(byte[] buffer, int offset, int count) => throw new NotSupportedException();

    /// <inheritdoc />
    public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();

    /// <inheritdoc />
    public override void SetLength(long value) => throw new NotSupportedException();
}
