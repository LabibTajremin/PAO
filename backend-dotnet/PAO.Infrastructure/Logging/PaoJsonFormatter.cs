using Serilog.Events;
using Serilog.Formatting;
using Serilog.Formatting.Json;

namespace PAO.Infrastructure.Logging;

/// <summary>
/// Writes one JSON object per line shaped like the NestJS logs (`time`, `level`, `msg`,
/// then the properties, `err` for an exception), so log queries keep working.
/// </summary>
public sealed class PaoJsonFormatter : ITextFormatter
{
    private static readonly JsonValueFormatter Values = new(typeTagName: null);

    /// <inheritdoc />
    public void Format(LogEvent logEvent, TextWriter output)
    {
        output.Write("{\"time\":\"");
        output.Write(logEvent.Timestamp.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ", System.Globalization.CultureInfo.InvariantCulture));
        output.Write("\",\"level\":\"");
        output.Write(LevelName(logEvent.Level));
        output.Write("\",\"msg\":");
        JsonValueFormatter.WriteQuotedJsonString(logEvent.RenderMessage(System.Globalization.CultureInfo.InvariantCulture), output);
        foreach (var (name, value) in logEvent.Properties)
        {
            output.Write(',');
            JsonValueFormatter.WriteQuotedJsonString(name, output);
            output.Write(':');
            Values.Format(value, output);
        }
        if (logEvent.Exception is { } error)
        {
            WriteError(error, output);
        }
        output.Write('}');
        output.Write('\n');
    }

    /// <summary>The level as the NestJS logs wrote it.</summary>
    public static string LevelName(LogEventLevel level) => level switch
    {
        LogEventLevel.Verbose => "TRACE",
        LogEventLevel.Debug => "DEBUG",
        LogEventLevel.Information => "INFO",
        LogEventLevel.Warning => "WARN",
        LogEventLevel.Error => "ERROR",
        _ => "FATAL",
    };

    private static void WriteError(Exception error, TextWriter output)
    {
        output.Write(",\"err\":{\"type\":");
        JsonValueFormatter.WriteQuotedJsonString(error.GetType().Name, output);
        output.Write(",\"message\":");
        JsonValueFormatter.WriteQuotedJsonString(error.Message, output);
        output.Write(",\"stack\":");
        JsonValueFormatter.WriteQuotedJsonString(error.ToString(), output);
        output.Write('}');
    }
}
