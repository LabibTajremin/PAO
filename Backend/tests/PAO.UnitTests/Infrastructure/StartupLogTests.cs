using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Registration;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class StartupLogTests
{
    [Fact]
    public void Warns_at_start_only_while_sms_verification_is_off()
    {
        var settings = TestSettings.Create();
        var logger = new RecordingLogger();
        PlatformStartup.WarnWhenSmsVerificationIsOff(settings, logger);
        Assert.Empty(logger.Entries);
        settings.Sms.VerificationEnabled = false;
        PlatformStartup.WarnWhenSmsVerificationIsOff(settings, logger);
        var (level, message) = Assert.Single(logger.Entries);
        Assert.Equal(LogLevel.Warning, level);
        Assert.StartsWith("SMS verification is OFF", message, StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("api", false, "background jobs: in worker", null)]
    [InlineData("api", true, "background jobs: in api", null)]
    [InlineData("worker", false, "background jobs: in worker", null)]
    [InlineData("worker", true, "background jobs: in worker", "JOBS_IN_API is true here too")]
    public void Names_the_process_that_runs_the_background_jobs(string host, bool inApi, string line, string? warning)
    {
        var settings = TestSettings.Create();
        settings.Jobs.RunInApi = inApi;
        var logger = new RecordingLogger();
        PlatformStartup.LogBackgroundJobs(settings, host, logger);
        Assert.Equal((LogLevel.Information, line), logger.Entries[0]);
        Assert.Equal(warning is null ? 1 : 2, logger.Entries.Count);
        if (warning is not null)
        {
            Assert.Equal(LogLevel.Warning, logger.Entries[1].Level);
            Assert.StartsWith(warning, logger.Entries[1].Message, StringComparison.Ordinal);
        }
    }

    private sealed class RecordingLogger : ILogger
    {
        public List<(LogLevel Level, string Message)> Entries { get; } = [];

        public IDisposable? BeginScope<TState>(TState state)
            where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) =>
            Entries.Add((logLevel, formatter(state, exception)));
    }
}
