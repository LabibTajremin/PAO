using System.Collections;
using Microsoft.Extensions.Configuration;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class ConfigurationTests : IDisposable
{
    private readonly string dir = Directory.CreateTempSubdirectory("pao-config").FullName;

    public void Dispose() => Directory.Delete(dir, recursive: true);

    [Fact]
    public void Files_hold_defaults_and_the_environment_variables_override_them()
    {
        File.WriteAllText(Path.Combine(dir, "http.json"), """{"Http":{"Address":":8081","RateLimitPerIp":5}}""");
        File.WriteAllText(Path.Combine(dir, "app.json"), """{"App":{"Environment":"dev"}}""");
        var env = new Hashtable { ["HTTP_ADDR"] = ":9999", ["APP_ENV"] = "", ["SMS_ADAPTER"] = "sslwireless" };
        var config = new ConfigurationBuilder().AddPaoConfiguration(dir, env).Build();
        var settings = PaoConfiguration.Bind(config);
        Assert.Equal(":9999", settings.Http.Address);
        Assert.Equal(5, settings.Http.RateLimitPerIp);
        Assert.Equal("dev", settings.App.Environment);
        Assert.Equal("sslwireless", settings.Sms.Adapter);
        Assert.Equal("console", new SmsOptions().Adapter);
    }

    [Fact]
    public void A_missing_config_directory_fails()
    {
        Assert.Throws<DirectoryNotFoundException>(() => new ConfigurationBuilder().AddPaoConfiguration(Path.Combine(dir, "none"), new Hashtable()));
    }

    [Fact]
    public void The_repository_config_files_bind_to_the_defaults()
    {
        var paths = PaoPaths.Resolve(AppContext.BaseDirectory, null);
        var settings = PaoConfiguration.Bind(new ConfigurationBuilder().AddPaoConfiguration(paths.Config, new Hashtable()).Build());
        Assert.Equal(":8080", settings.Http.Address);
        Assert.Equal("k1", settings.Jwt.KeyId);
        Assert.Equal(587, settings.Smtp.Port);
        Assert.Equal(250, settings.Jobs.OutboxRelayIntervalMs);
        Assert.Equal("log", settings.Push.Adapter);
        Assert.Equal("info", settings.Logging.Level);
    }

    [Fact]
    public void Deployment_variables_map_every_documented_name()
    {
        var env = new Hashtable();
        foreach (var name in EnvironmentVariables.Keys.Keys)
        {
            env[name] = "x";
        }
        Assert.Equal(EnvironmentVariables.Keys.Count, EnvironmentVariables.Map(env).Count);
        Assert.Empty(EnvironmentVariables.Map(new Hashtable { ["DATABASE_URL"] = "" }));
    }

    [Fact]
    public void Valid_settings_pass_and_expose_only_safe_log_fields()
    {
        var settings = TestSettings.Create();
        Assert.Same(settings, ConfigValidator.Validate(settings));
        Assert.Equal(["app_env", "http_addr", "jwt_key_id", "push_adapter", "sms_adapter"], settings.LogFields().Keys.Order());
    }

    [Fact]
    public void Every_problem_is_reported_at_once_with_stable_messages()
    {
        var s = TestSettings.Create();
        s.App.Environment = "qa";
        s.Logging.Level = "loud";
        s.Http.Address = "nope";
        s.Http.MetricsAddress = "nope";
        s.Database.Url = string.Empty;
        s.Jwt.SigningKey = "AAAA";
        s.Jwt.PreviousPublicKeys = "old:AAAA,:x,k0";
        s.App.DataEncryptionKey = string.Empty;
        s.App.DataEncryptionPreviousKeys = "AAAA";
        s.App.AdminCorsOrigin = "https://admin.pao.com.bd/, https://preview.pao.com.bd";
        s.Sms.Adapter = "pigeon";
        s.Push.Adapter = "carrier";
        var error = Assert.Throws<ConfigException>(() => ConfigValidator.Validate(s));
        Assert.Contains("APP_ENV must be one of dev, test, staging, prod", error.Problems);
        Assert.Contains("LOG_LEVEL must be debug, info, warn or error", error.Problems);
        Assert.Contains("HTTP_ADDR must be a host:port listen address", error.Problems);
        Assert.Contains("METRICS_ADDR must be a host:port listen address", error.Problems);
        Assert.Contains("DATABASE_URL is required", error.Problems);
        Assert.Contains("JWT_SIGNING_KEY must be 32 bytes, base64-encoded", error.Problems);
        Assert.Contains("JWT_PREVIOUS_PUBLIC_KEYS entry \"old\" must be kid:base64-public-key", error.Problems);
        Assert.Contains("JWT_PREVIOUS_PUBLIC_KEYS entry \"k0\" must be kid:base64-public-key", error.Problems);
        Assert.Contains("DATA_ENCRYPTION_KEY is required", error.Problems);
        Assert.Contains("DATA_ENCRYPTION_PREVIOUS_KEYS entries must be 32 bytes, base64-encoded", error.Problems);
        Assert.Contains("ADMIN_CORS_ORIGIN must be one or more comma-separated http(s) origins without a path", error.Problems);
        Assert.Contains("SMS_ADAPTER must be one of console, sslwireless", error.Problems);
        Assert.Contains("PUSH_ADAPTER must be one of log, fcm", error.Problems);
        Assert.StartsWith("invalid configuration: ", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Real_adapters_need_their_credentials_and_production_needs_real_adapters()
    {
        var s = TestSettings.Create(appEnv: AppEnvironments.Prod);
        var fake = Assert.Throws<ConfigException>(() => ConfigValidator.Validate(s));
        Assert.Equal(["production needs real SMS_ADAPTER and PUSH_ADAPTER"], fake.Problems);
        s.Sms.Adapter = "sslwireless";
        s.Push.Adapter = "fcm";
        var missing = Assert.Throws<ConfigException>(() => ConfigValidator.Validate(s));
        Assert.Equal(["SSLWIRELESS_API_TOKEN is required", "SSLWIRELESS_SID is required", "FCM_CREDENTIALS_FILE or FCM_CREDENTIALS_JSON is required"], missing.Problems);
        s.Sms.SslWirelessApiToken = "t";
        s.Sms.SslWirelessSid = "s";
        s.Push.FcmCredentialsJson = "{}";
        ConfigValidator.Validate(s);
        s.Push.FcmCredentialsJson = string.Empty;
        s.Push.FcmCredentialsFile = "/run/fcm.json";
        ConfigValidator.Validate(s);
    }

    [Theory]
    [InlineData("http://localhost:5000", true)]
    [InlineData("https://admin.pao.com.bd, https://pao-admin-git-main.vercel.app", true)]
    [InlineData("https://admin.pao.com.bd,", true)]
    [InlineData("", false)]
    [InlineData(" , ", false)]
    [InlineData("admin.pao.com.bd", false)]
    [InlineData("ftp://admin.pao.com.bd", false)]
    [InlineData("https://admin.pao.com.bd/app", false)]
    [InlineData("https://user@admin.pao.com.bd", false)]
    [InlineData("https://admin.pao.com.bd?x=1", false)]
    public void Admin_cors_origin_takes_one_or_more_origins(string value, bool valid)
    {
        var s = TestSettings.Create();
        s.App.AdminCorsOrigin = value;
        Assert.Equal(valid, Record.Exception(() => ConfigValidator.Validate(s)) is null);
    }

    [Fact]
    public void Data_keys_and_fcm_credentials_parse()
    {
        var problems = new List<string>();
        Assert.Equal(2, ConfigValidator.DataKeys($"{TestEnvironment.Key}, ,{TestEnvironment.Key}", problems).Count);
        Assert.Empty(problems);
        Assert.Equal(["DATA_ENCRYPTION_PREVIOUS_KEYS entries must be 32 bytes, base64-encoded"], (ConfigValidator.DataKeys("x", problems), problems).problems);
        const string json = """{"project_id":"p"}""";
        Assert.Equal(json, FcmCredentials.Read(new PushOptions { FcmCredentialsJson = " " + json }));
        Assert.Equal(json, FcmCredentials.Read(new PushOptions { FcmCredentialsJson = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(json)) }));
        var file = Path.GetTempFileName();
        File.WriteAllText(file, json);
        Assert.Equal(json, FcmCredentials.Read(new PushOptions { FcmCredentialsFile = file, FcmCredentialsJson = "ignored" }));
        File.Delete(file);
    }

    [Fact]
    public void Previous_keys_parse_into_raw_bytes()
    {
        var problems = new List<string>();
        var keys = ConfigValidator.PreviousKeys($"old:{TestEnvironment.Key},,older:{TestEnvironment.Key}", problems);
        Assert.Empty(problems);
        Assert.Equal(["old", "older"], keys.Keys.Order());
        Assert.Equal(32, keys["old"].Length);
    }

    [Theory]
    [InlineData("AAAA", 3)]
    [InlineData("AAA=", 2)]
    [InlineData("AA==", 1)]
    [InlineData("", 0)]
    [InlineData("AAA", null)]
    [InlineData("AA-_", null)]
    public void Base64_is_decoded_strictly(string text, int? length)
    {
        Assert.Equal(length, StrictBase64.Decode(text)?.Length);
    }
}

public sealed class HostingPathTests
{
    [Theory]
    [InlineData(":8080", null, 8080, "http://0.0.0.0:8080")]
    [InlineData("127.0.0.1:0", "127.0.0.1", 0, "http://127.0.0.1:0")]
    [InlineData("[::1]:9090", "::1", 9090, "http://[::1]:9090")]
    public void Parses_go_listen_addresses(string text, string? host, int port, string url)
    {
        var address = ListenAddress.Parse(text);
        Assert.Equal(host, address.Host);
        Assert.Equal(port, address.Port);
        Assert.Equal(url, address.ToUrl());
        Assert.True(ListenAddress.IsValid(text));
    }

    [Theory]
    [InlineData("8080")]
    [InlineData(":99999")]
    [InlineData("host:")]
    public void Rejects_invalid_listen_addresses(string text)
    {
        Assert.False(ListenAddress.IsValid(text));
    }

    [Fact]
    public void Finds_the_backend_folder_or_honours_pao_home()
    {
        var found = PaoPaths.Resolve(AppContext.BaseDirectory, null);
        Assert.True(File.Exists(Path.Combine(found.Home, "PAO.sln")));
        Assert.EndsWith("Config", found.Config, StringComparison.Ordinal);
        Assert.EndsWith("DB Changes", found.Migrations, StringComparison.Ordinal);
        Assert.EndsWith(Path.Combine("Spec", "openapi.gen.yaml"), found.Spec, StringComparison.Ordinal);
        Assert.Equal("/srv/pao", PaoPaths.Resolve(AppContext.BaseDirectory, "/srv/pao").Home);
        var outside = Directory.CreateTempSubdirectory("pao-paths").FullName;
        Assert.Equal(outside, PaoPaths.Resolve(outside, null).Home);
        Directory.Delete(outside);
        Assert.Equal(AppContext.BaseDirectory, PaoPaths.Current().BaseDirectory);
    }
}

public sealed class LocalSettingsFileTests : IDisposable
{
    private readonly string dir = Directory.CreateTempSubdirectory("pao-local").FullName;

    public void Dispose() => Directory.Delete(dir, recursive: true);

    [Theory]
    [InlineData("APP_ENV", "dev", "local")]
    [InlineData("App__Environment", "test", "local")]
    [InlineData("APP_ENV", " Prod ", "file")]
    [InlineData("App__Environment", "staging", "file")]
    public void The_local_file_overrides_the_defaults_outside_staging_and_prod(string key, string appEnv, string expected)
    {
        var config = WriteLocalLayout();
        File.WriteAllText(Path.Combine(dir, PaoConfiguration.LocalFileName), """{"Redis":{"Url":"local"}}""");
        var built = new ConfigurationBuilder().AddPaoConfiguration(config, new Hashtable { [key] = appEnv }).Build();
        Assert.Equal(expected, PaoConfiguration.Bind(built).Redis.Url);
    }

    [Fact]
    public void Without_a_local_file_the_defaults_stand()
    {
        var built = new ConfigurationBuilder().AddPaoConfiguration(WriteLocalLayout(), new Hashtable()).Build();
        Assert.Equal("file", PaoConfiguration.Bind(built).Redis.Url);
    }

    [Fact]
    public void The_committed_example_binds_and_passes_validation()
    {
        var paths = PaoPaths.Resolve(AppContext.BaseDirectory, null);
        var example = new ConfigurationBuilder()
            .AddPaoConfiguration(paths.Config, new Hashtable())
            .AddJsonFile(Path.Combine(paths.Home, "appsettings.Local.example.json"), optional: false)
            .Build();
        var settings = ConfigValidator.Validate(PaoConfiguration.Bind(example));
        Assert.Equal("dev", settings.App.Environment);
        Assert.Equal("console", settings.Sms.Adapter);
        Assert.NotEmpty(settings.Jwt.SigningKey);
        Assert.StartsWith("postgres://", settings.Database.Url);
    }

    private string WriteLocalLayout()
    {
        var config = Path.Combine(dir, "Config");
        Directory.CreateDirectory(config);
        File.WriteAllText(Path.Combine(config, "redis.json"), """{"Redis":{"Url":"file"}}""");
        return config;
    }
}
