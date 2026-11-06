using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Registration;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class SmsVerificationWarningTests
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
