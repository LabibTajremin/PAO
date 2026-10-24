using System.Text.Json;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Logging;
using Serilog;
using Serilog.Events;
using Serilog.Parsing;

namespace PAO.UnitTests.Infrastructure;

public sealed class LoggingTests : IDisposable
{
    private readonly string dir = Directory.CreateTempSubdirectory("pao-logs").FullName;

    public void Dispose() => Directory.Delete(dir, recursive: true);

    private static LogEvent Event(DateTimeOffset at, LogEventLevel level, Exception? error = null) => new(
        at, level, error, new MessageTemplateParser().Parse("hello {Name}"),
        [new LogEventProperty("Name", new ScalarValue("pao")), new LogEventProperty("request_id", new ScalarValue("r-1"))]);

    [Fact]
    public void Writes_one_nestjs_shaped_json_line_per_event()
    {
        var output = new StringWriter();
        new PaoJsonFormatter().Format(Event(new DateTimeOffset(2026, 10, 17, 1, 2, 3, 4, TimeSpan.Zero), LogEventLevel.Warning, new InvalidOperationException("boom")), output);
        var line = output.ToString();
        Assert.EndsWith("}\n", line, StringComparison.Ordinal);
        using var json = JsonDocument.Parse(line);
        var root = json.RootElement;
        Assert.Equal("2026-10-17T01:02:03.004Z", root.GetProperty("time").GetString());
        Assert.Equal("WARN", root.GetProperty("level").GetString());
        Assert.Equal("hello \"pao\"", root.GetProperty("msg").GetString());
        Assert.Equal("r-1", root.GetProperty("request_id").GetString());
        Assert.Equal("InvalidOperationException", root.GetProperty("err").GetProperty("type").GetString());
        Assert.Equal("boom", root.GetProperty("err").GetProperty("message").GetString());
    }

    [Theory]
    [InlineData(LogEventLevel.Verbose, "TRACE")]
    [InlineData(LogEventLevel.Debug, "DEBUG")]
    [InlineData(LogEventLevel.Information, "INFO")]
    [InlineData(LogEventLevel.Warning, "WARN")]
    [InlineData(LogEventLevel.Error, "ERROR")]
    [InlineData(LogEventLevel.Fatal, "FATAL")]
    public void Names_levels_as_nestjs_did(LogEventLevel level, string name)
    {
        Assert.Equal(name, PaoJsonFormatter.LevelName(level));
    }

    [Theory]
    [InlineData("debug", LogEventLevel.Debug)]
    [InlineData("INFO", LogEventLevel.Information)]
    [InlineData("warn", LogEventLevel.Warning)]
    [InlineData("error", LogEventLevel.Error)]
    public void Maps_log_level_names(string name, LogEventLevel level)
    {
        Assert.Equal(level, LoggingSetup.LevelOf(name));
    }

    [Fact]
    public void Files_go_to_one_folder_per_dhaka_day()
    {
        using (var sink = new DateFolderFileSink(dir, "api", new PaoJsonFormatter()))
        {
            sink.Emit(Event(new DateTimeOffset(2026, 10, 17, 17, 0, 0, TimeSpan.Zero), LogEventLevel.Information));
            sink.Emit(Event(new DateTimeOffset(2026, 10, 17, 17, 30, 0, TimeSpan.Zero), LogEventLevel.Information));
            sink.Emit(Event(new DateTimeOffset(2026, 10, 17, 18, 0, 0, TimeSpan.Zero), LogEventLevel.Information));
        }
        Assert.Equal(2, File.ReadAllLines(Path.Combine(dir, "2026-10-17", "pao-api.log")).Length);
        Assert.Single(File.ReadAllLines(Path.Combine(dir, "2026-10-18", "pao-api.log")));
    }

    [Fact]
    public void Configures_console_and_date_folders_relative_to_the_backend_home()
    {
        var withFiles = LoggingSetup.Configure(new LoggerConfiguration(), new LoggingOptions { Directory = "Logs", Level = "debug" }, "worker", dir);
        using (var logger = withFiles.CreateLogger())
        {
            logger.Information("started {Host}", "worker");
            Assert.True(logger.IsEnabled(LogEventLevel.Debug));
        }
        Assert.Single(Directory.GetDirectories(Path.Combine(dir, "Logs")));
        var absolute = Path.Combine(dir, "abs");
        using (var logger = LoggingSetup.Configure(new LoggerConfiguration(), new LoggingOptions { Directory = absolute }, "api", "/nowhere").CreateLogger())
        {
            logger.Warning("absolute");
        }
        Assert.True(Directory.Exists(absolute));
        using var consoleOnly = LoggingSetup.Configure(new LoggerConfiguration(), new LoggingOptions { WriteFiles = false }, "api", dir).CreateLogger();
        Assert.False(consoleOnly.IsEnabled(LogEventLevel.Debug));
    }
}
