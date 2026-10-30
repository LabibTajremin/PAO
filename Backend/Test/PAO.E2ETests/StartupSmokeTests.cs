using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using PAO.Infrastructure.Hosting;
using PAO.TestKit;

namespace PAO.E2ETests;

/// <summary>Runs the three built hosts as processes, as the image does, against the provided services.</summary>
public sealed class StartupSmokeTests : IAsyncLifetime
{
    private static readonly string Home = PaoPaths.Resolve(AppContext.BaseDirectory, null).Home;
    private string databaseUrl = string.Empty;

    public async ValueTask InitializeAsync() => databaseUrl = await TestDatabases.CreateEmpty();

    public async ValueTask DisposeAsync() => await TestDatabases.Drop(databaseUrl);

    private static string Dll(string project)
    {
        var release = AppContext.BaseDirectory.Contains($"{Path.DirectorySeparatorChar}Release{Path.DirectorySeparatorChar}", StringComparison.Ordinal);
        return Path.Combine(Home, project, "bin", release ? "Release" : "Debug", "net10.0", project + ".dll");
    }

    private static int FreePort()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        return ((IPEndPoint)listener.LocalEndpoint).Port;
    }

    private Process Start(string project, Dictionary<string, string> environment, params string[] args)
    {
        var info = new ProcessStartInfo("dotnet") { RedirectStandardOutput = true, RedirectStandardError = true };
        info.ArgumentList.Add(Dll(project));
        foreach (var arg in args)
        {
            info.ArgumentList.Add(arg);
        }
        foreach (var (key, value) in environment)
        {
            info.Environment[key] = value;
        }
        info.Environment["Logging__WriteFiles"] = "false";
        var process = Process.Start(info)!;
        process.OutputDataReceived += (_, _) => { };
        process.BeginOutputReadLine();
        process.ErrorDataReceived += (_, _) => { };
        process.BeginErrorReadLine();
        return process;
    }

    private Dictionary<string, string> Environment(int http, int metrics)
    {
        var env = TestSettings.Environment(databaseUrl);
        env["HTTP_ADDR"] = $"127.0.0.1:{http}";
        env["METRICS_ADDR"] = $"127.0.0.1:{metrics}";
        return env;
    }

    private static async Task<HttpResponseMessage> Poll(string url)
    {
        using var http = new HttpClient();
        for (var i = 0; i < 160; i++)
        {
            try
            {
                return await http.GetAsync(url);
            }
            catch (HttpRequestException)
            {
                await Task.Delay(250);
            }
        }
        throw new TimeoutException(url);
    }

    private static async Task Stop(Process process)
    {
        process.Kill(entireProcessTree: true);
        await process.WaitForExitAsync();
    }

    [Fact]
    public async Task The_migrator_api_and_worker_start_and_answer()
    {
        using var usage = Start("PAO.Migrator", TestSettings.Environment(databaseUrl));
        await usage.WaitForExitAsync();
        Assert.Equal(2, usage.ExitCode);
        using var migrate = Start("PAO.Migrator", TestSettings.Environment(databaseUrl), "up");
        await migrate.WaitForExitAsync();
        Assert.Equal(0, migrate.ExitCode);

        var (http, metrics) = (FreePort(), FreePort());
        using var api = Start("PAO.Core", Environment(http, metrics));
        Assert.Equal(HttpStatusCode.OK, (await Poll($"http://127.0.0.1:{http}/healthz")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await Poll($"http://127.0.0.1:{http}/readyz")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await Poll($"http://127.0.0.1:{http}/v1/nothing")).StatusCode);
        Assert.Contains("pao_http_requests_total", await (await Poll($"http://127.0.0.1:{metrics}/metrics")).Content.ReadAsStringAsync(), StringComparison.Ordinal);
        await Stop(api);

        var workerMetrics = FreePort();
        using var worker = Start("PAO.Worker", Environment(FreePort(), workerMetrics));
        Assert.Equal(HttpStatusCode.OK, (await Poll($"http://127.0.0.1:{workerMetrics}/healthz")).StatusCode);
        await Stop(worker);
    }

    [Fact]
    public async Task A_host_with_invalid_configuration_exits_with_an_error()
    {
        var env = TestSettings.Environment(databaseUrl);
        env["JWT_SIGNING_KEY"] = "short";
        var info = new ProcessStartInfo("dotnet") { RedirectStandardError = true, RedirectStandardOutput = true };
        info.ArgumentList.Add(Dll("PAO.Core"));
        foreach (var (key, value) in env)
        {
            info.Environment[key] = value;
        }
        using var process = Process.Start(info)!;
        var error = await process.StandardError.ReadToEndAsync();
        await process.WaitForExitAsync();
        Assert.Equal(1, process.ExitCode);
        Assert.Contains("JWT_SIGNING_KEY must be 32 bytes", error, StringComparison.Ordinal);
    }
}
