using System.Net;
using System.Net.Http.Headers;
using System.Net.Sockets;
using PAO.Core.Areas.Catalog.Services.Icons;
using PAO.Core.Registration;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.UnitTests.Areas.Catalog;

public sealed class IconLinkTests
{
    private sealed class Stub(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> answer) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) => answer(request, cancellationToken);
    }

    private static IconFetcher Fetcher(Func<HttpResponseMessage> answer) => new(new HttpClient(new Stub((_, _) => Task.FromResult(answer()))));

    private static HttpResponseMessage File(string type, byte[] body, bool length = true)
    {
        HttpContent content = length ? new ByteArrayContent(body) : new StreamContent(new MemoryStream(body));
        content.Headers.ContentType = new MediaTypeHeaderValue(type);
        return new HttpResponseMessage(HttpStatusCode.OK) { Content = content };
    }

    private static async Task<string> Reason(Task task) => (await Assert.ThrowsAsync<DomainException>(() => task)).Reason;

    [Theory]
    [InlineData("8.8.8.8", true)]
    [InlineData("2606:4700:4700::1111", true)]
    [InlineData("::ffff:1.1.1.1", true)]
    [InlineData("0.0.0.0", false)]
    [InlineData("10.1.2.3", false)]
    [InlineData("100.64.0.1", false)]
    [InlineData("127.0.0.1", false)]
    [InlineData("169.254.169.254", false)]
    [InlineData("172.16.0.1", false)]
    [InlineData("172.31.255.255", false)]
    [InlineData("192.0.0.8", false)]
    [InlineData("192.168.1.1", false)]
    [InlineData("198.18.0.1", false)]
    [InlineData("224.0.0.1", false)]
    [InlineData("255.255.255.255", false)]
    [InlineData("::ffff:10.0.0.1", false)]
    [InlineData("::1", false)]
    [InlineData("::", false)]
    [InlineData("fe80::1", false)]
    [InlineData("fec0::1", false)]
    [InlineData("fd00::1", false)]
    [InlineData("ff02::1", false)]
    [InlineData("64:ff9b::a00:1", false)]
    public void Only_public_addresses_are_reachable(string ip, bool reachable) =>
        Assert.Equal(reachable, PublicAddresses.IsPublic(IPAddress.Parse(ip)));

    [Fact]
    public async Task Hosts_that_resolve_to_a_private_address_are_refused_before_connecting()
    {
        var mixed = new PublicAddresses((_, _) => Task.FromResult(new[] { IPAddress.Parse("8.8.8.8"), IPAddress.Loopback }), PublicAddresses.IsPublic);
        await Assert.ThrowsAsync<HttpRequestException>(async () => await mixed.Connect(new DnsEndPoint("x.example", 443), CancellationToken.None));
        var none = new PublicAddresses((_, _) => Task.FromResult(Array.Empty<IPAddress>()), _ => true);
        await Assert.ThrowsAsync<HttpRequestException>(async () => await none.Connect(new DnsEndPoint("x.example", 443), CancellationToken.None));
        await Assert.ThrowsAsync<HttpRequestException>(async () => await new PublicAddresses().Connect(new DnsEndPoint("localhost", 443), CancellationToken.None));
    }

    [Fact]
    public async Task Allowed_addresses_are_connected_and_failures_close_the_socket()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        var loopback = new PublicAddresses((_, _) => Task.FromResult(new[] { IPAddress.Loopback }), _ => true);
        await using (var stream = await loopback.Connect(new DnsEndPoint("icons.example", port), CancellationToken.None))
        {
            Assert.True(stream.CanWrite);
        }
        listener.Stop();
        await Assert.ThrowsAnyAsync<SocketException>(async () => await loopback.Connect(new DnsEndPoint("icons.example", port), CancellationToken.None));
    }

    [Fact]
    public void The_icon_client_follows_no_redirects_and_skips_proxies()
    {
        using var handler = CatalogAreaRegistration.IconHandler(new PublicAddresses());
        Assert.False(handler.AllowAutoRedirect);
        Assert.False(handler.UseProxy);
        Assert.NotNull(handler.ConnectCallback);
    }

    [Fact]
    public async Task A_link_returns_the_file_and_its_type()
    {
        var (type, file) = await Fetcher(() => File(IconTypes.Svg, [1, 2, 3])).Fetch("https://cdn.example/icon.svg", CancellationToken.None);
        Assert.Equal(IconTypes.Svg, type);
        Assert.Equal([1, 2, 3], file);
        var (_, streamed) = await Fetcher(() => File(IconTypes.Png, [4, 5], length: false)).Fetch("https://cdn.example/icon.png", CancellationToken.None);
        Assert.Equal([4, 5], streamed);
    }

    [Fact]
    public async Task Bad_links_and_bad_answers_are_refused()
    {
        var ok = Fetcher(() => File(IconTypes.Svg, [1]));
        Assert.Equal(CatalogReasons.IconLinkFailed, await Reason(ok.Fetch("http://cdn.example/icon.svg", CancellationToken.None)));
        Assert.Equal(CatalogReasons.IconLinkFailed, await Reason(ok.Fetch("not a url", CancellationToken.None)));
        Assert.Equal(CatalogReasons.IconLinkFailed, await Reason(Fetcher(() => new HttpResponseMessage(HttpStatusCode.NotFound)).Fetch("https://x.example/a", CancellationToken.None)));
        Assert.Equal(CatalogReasons.IconUnreadable, await Reason(Fetcher(() => File("image/gif", [1])).Fetch("https://x.example/a", CancellationToken.None)));
        Assert.Equal(CatalogReasons.IconUnreadable, await Reason(Fetcher(() => new HttpResponseMessage(HttpStatusCode.OK) { Content = new ByteArrayContent([1]) }).Fetch("https://x.example/a", CancellationToken.None)));
        var big = new byte[IconTypes.MaxSvgBytes + 1];
        Assert.Equal(CatalogReasons.IconTooLarge, await Reason(Fetcher(() => File(IconTypes.Svg, big)).Fetch("https://x.example/a", CancellationToken.None)));
        Assert.Equal(CatalogReasons.IconTooLarge, await Reason(Fetcher(() => File(IconTypes.Svg, big, length: false)).Fetch("https://x.example/a", CancellationToken.None)));
        var down = new IconFetcher(new HttpClient(new Stub((_, _) => throw new HttpRequestException("refused"))));
        Assert.Equal(CatalogReasons.IconLinkFailed, await Reason(down.Fetch("https://x.example/a", CancellationToken.None)));
    }

    [Fact]
    public async Task A_slow_link_fails_but_a_cancelled_request_stays_cancelled()
    {
        var slow = new IconFetcher(new HttpClient(new Stub(async (_, token) =>
        {
            await Task.Delay(Timeout.Infinite, token);
            return new HttpResponseMessage();
        })));
        var started = DateTime.UtcNow;
        Assert.Equal(CatalogReasons.IconLinkFailed, await Reason(slow.Fetch("https://x.example/a", CancellationToken.None)));
        Assert.True(DateTime.UtcNow - started >= IconFetcher.Timeout - TimeSpan.FromMilliseconds(100));
        using var cancelled = new CancellationTokenSource();
        await cancelled.CancelAsync();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => slow.Fetch("https://x.example/a", cancelled.Token));
    }
}
