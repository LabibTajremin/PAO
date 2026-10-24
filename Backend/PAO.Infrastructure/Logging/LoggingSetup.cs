using PAO.Infrastructure.Configuration;
using Serilog;
using Serilog.Events;

namespace PAO.Infrastructure.Logging;

/// <summary>Builds the Serilog logger every host uses: JSON to stdout and to date folders.</summary>
public static class LoggingSetup
{
    /// <summary>The Serilog level for a LOG_LEVEL value.</summary>
    public static LogEventLevel LevelOf(string level) => level.ToLowerInvariant() switch
    {
        "debug" => LogEventLevel.Debug,
        "warn" => LogEventLevel.Warning,
        "error" => LogEventLevel.Error,
        _ => LogEventLevel.Information,
    };

    /// <summary>
    /// Configures `logger` for `host` (api, worker, migrate). Framework noise below warning
    /// is dropped, as Nest's own logs were routed at their levels.
    /// </summary>
    public static LoggerConfiguration Configure(LoggerConfiguration logger, LoggingOptions options, string host, string baseDirectory)
    {
        var formatter = new PaoJsonFormatter();
        logger
            .MinimumLevel.Is(LevelOf(options.Level))
            .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
            .MinimumLevel.Override("System", LogEventLevel.Warning)
            .Enrich.FromLogContext()
            .WriteTo.Console(formatter);
        if (options.WriteFiles)
        {
            var root = Path.IsPathRooted(options.Directory) ? options.Directory : Path.Combine(baseDirectory, options.Directory);
            logger.WriteTo.Sink(new DateFolderFileSink(root, host, formatter));
        }
        return logger;
    }
}
