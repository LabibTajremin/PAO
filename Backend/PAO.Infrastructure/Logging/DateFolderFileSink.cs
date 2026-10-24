using System.Globalization;
using System.Text;
using PAO.Infrastructure.Data;
using Serilog.Core;
using Serilog.Events;
using Serilog.Formatting;

namespace PAO.Infrastructure.Logging;

/// <summary>
/// Appends log lines to `{root}/{yyyy-MM-dd}/pao-{host}.log`, one folder per Asia/Dhaka
/// calendar day (ADR-0034), switching folders at local midnight.
/// </summary>
public sealed class DateFolderFileSink(string root, string host, ITextFormatter formatter) : ILogEventSink, IDisposable
{
    private readonly Lock gate = new();
    private string? openDay;
    private StreamWriter? writer;

    /// <summary>The file a line logged at `at` goes to.</summary>
    public string PathFor(DateTimeOffset at) =>
        Path.Combine(root, DayOf(at), $"pao-{host}.log");

    /// <inheritdoc />
    public void Emit(LogEvent logEvent)
    {
        lock (gate)
        {
            var day = DayOf(logEvent.Timestamp);
            if (day != openDay || writer is null)
            {
                Open(logEvent.Timestamp, day);
            }
            formatter.Format(logEvent, writer!);
            writer!.Flush();
        }
    }

    /// <inheritdoc />
    public void Dispose()
    {
        lock (gate)
        {
            writer?.Dispose();
            writer = null;
        }
    }

    private static string DayOf(DateTimeOffset at) =>
        at.ToOffset(DhakaTime.Offset).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    private void Open(DateTimeOffset at, string day)
    {
        writer?.Dispose();
        var path = PathFor(at);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        writer = new StreamWriter(new FileStream(path, FileMode.Append, FileAccess.Write, FileShare.ReadWrite), new UTF8Encoding(false));
        openDay = day;
    }
}
