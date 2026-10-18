using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PAO.BackgroundJobs;
using PAO.Core;
using PAO.Core.Registration;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Push;
using PAO.Infrastructure.Registration;
using PAO.Infrastructure.Sms;
using PAO.Infrastructure.Storage;
using PAO.Infrastructure.Testing;
using PAO.TestKit;
using PAO.Worker;

namespace PAO.IntegrationTests;

public sealed class StorageTests
{
    private static ObjectStore Store() => new(TestSettings.Create().Storage);

    [Fact]
    public async Task Creates_buckets_presigns_and_manages_objects()
    {
        using var store = Store();
        var bucket = TestEnvironment.Unique("pao-net-");
        await store.EnsureBucket(bucket, CancellationToken.None);
        await store.EnsureBucket(bucket, CancellationToken.None);
        await store.Ping(bucket, CancellationToken.None);
        var upload = await store.PresignPut(bucket, "docs/a.txt", "text/plain", TimeSpan.FromMinutes(5));
        using var http = new HttpClient();
        var content = new ByteArrayContent("hello"u8.ToArray());
        content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(upload.Headers["Content-Type"]);
        var put = await http.PutAsync(upload.Url, content);
        Assert.True(put.IsSuccessStatusCode, await put.Content.ReadAsStringAsync());
        Assert.Equal(new ObjectInfo(5, "text/plain"), await store.Head(bucket, "docs/a.txt", CancellationToken.None));
        Assert.Equal("hello", await http.GetStringAsync(await store.PresignGet(bucket, "docs/a.txt", TimeSpan.FromMinutes(5))));
        await store.Put(bucket, "b.txt", "text/plain", new MemoryStream("x"u8.ToArray()), CancellationToken.None);
        await store.Delete(bucket, "b.txt", CancellationToken.None);
        await Assert.ThrowsAsync<ObjectNotFoundException>(() => store.Head(bucket, "b.txt", CancellationToken.None));
        await store.Delete(bucket, "docs/a.txt", CancellationToken.None);
    }

    [Fact]
    public async Task Head_failures_other_than_not_found_propagate()
    {
        using var store = Store();
        await Assert.ThrowsAnyAsync<Exception>(() => store.Head("Bad_Bucket_Name!", "x", CancellationToken.None));
        var https = TestSettings.Create().Storage;
        https.PublicEndpoint = "https://files.pao.test";
        using var secure = new ObjectStore(https);
        Assert.StartsWith("https://files.pao.test/", await secure.PresignGet("b", "k", TimeSpan.FromMinutes(1)), StringComparison.Ordinal);
    }
}

public sealed class HostTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>
{
    [Fact]
    public async Task The_api_runs_with_its_metrics_server_until_stopped()
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { ContentRootPath = AppContext.BaseDirectory });
        builder.WebHost.UseTestServer();
        var settings = builder.AddPaoSettings(Hosts.Paths, Hosts.Environment(database.Url, AppEnvironments.Dev), "api");
        builder.Services.AddBuiltInServices(settings, Hosts.Paths.Spec, typeof(ApiHost).Assembly)
            .AddCustomServices(settings, typeof(ApiHost).Assembly).AddDatabase(settings).AddRepositories().AddAreas();
        var app = builder.Build();
        PAO.Infrastructure.Http.HttpEdge.UseHttpEdge(app, settings);
        var running = app.RunApi(settings, web => web.UseTestServer());
        // Start-up checks can take longer than any fixed delay on a loaded machine.
        await Task.Delay(Timeout.Infinite, app.Lifetime.ApplicationStarted).ContinueWith(_ => { }, TaskScheduler.Default);
        Assert.IsType<ConsoleSmsSender>(app.Services.GetRequiredService<ISmsSender>());
        await app.StopAsync();
        Assert.Equal(0, await running);
        await app.DisposeAsync();
    }

    [Fact]
    public async Task The_worker_runs_its_internal_server_until_stopped()
    {
        var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { ContentRootPath = AppContext.BaseDirectory });
        var settings = builder.AddPaoSettings(Hosts.Paths, Hosts.Environment(database.Url), "worker");
        builder.Services.AddBuiltInServices(settings).AddCustomServices(settings, typeof(ApiHost).Assembly)
            .AddDatabase(settings).AddRepositories().AddAreas().AddBackgroundJobs(Hosts.Paths);
        using var host = builder.Build();
        var running = host.RunWorker(settings, web => web.UseTestServer());
        await Task.Delay(500);
        Assert.NotNull(host.Services.GetRequiredService<ISmsCapture>());
        Assert.Equal(3, WorkerHost.Handlers(settings).Length);
        await host.StopAsync();
        Assert.Equal(0, await running);
        Assert.Equal(2, WorkerHost.Handlers(TestSettings.Create(appEnv: AppEnvironments.Dev)).Length);
    }

    [Fact]
    public async Task Health_checks_probe_the_local_hosts()
    {
        var ok = new StubHandler(HttpStatusCode.OK);
        Assert.Equal(0, await ApiHost.HealthCheck(ok));
        Assert.Equal(1, await WorkerHost.HealthCheck(new StubHandler(HttpStatusCode.ServiceUnavailable)));
        Assert.Equal(1, await ApiHost.HealthCheck(url: "http://127.0.0.1:1/healthz"));
        Assert.Equal(1, await WorkerHost.HealthCheck(url: "http://127.0.0.1:1/healthz"));
    }

    [Fact]
    public void Real_adapters_are_registered_from_their_settings()
    {
        var settings = TestSettings.Create(appEnv: AppEnvironments.Dev);
        settings.Sms.Adapter = "sslwireless";
        settings.Push.Adapter = "fcm";
        var credentials = Path.GetTempFileName();
        using (var rsa = System.Security.Cryptography.RSA.Create(2048))
        {
            File.WriteAllText(credentials, System.Text.Json.JsonSerializer.Serialize(new { project_id = "p", client_email = "e@p", private_key = rsa.ExportPkcs8PrivateKeyPem() }));
        }
        settings.Push.FcmCredentialsFile = credentials;
        using var services = new ServiceCollection().AddLogging().AddBuiltInServices(settings).AddCustomServices(settings).BuildServiceProvider();
        Assert.IsType<SslWirelessSmsSender>(services.GetRequiredService<ISmsSender>());
        Assert.IsType<FcmPushSender>(services.GetRequiredService<IPushSender>());
        Assert.Null(services.GetService<IPushCapture>());
        File.Delete(credentials);
    }

    private sealed class StubHandler(HttpStatusCode status) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(status));
    }
}
