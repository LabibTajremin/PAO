using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Http.Edge;

namespace PAO.UnitTests.Http;

public sealed record BodyProbe(string? Name, int Count);

public sealed class EdgeBodyBinderTests
{
    private static readonly EmptyModelMetadataProvider Metadata = new();

    private static async Task<object?> Bind(JsonNode? body, Type type)
    {
        var http = new DefaultHttpContext();
        http.Edge().Body = body;
        var context = new DefaultModelBindingContext
        {
            ActionContext = new ActionContext { HttpContext = http },
            ModelMetadata = Metadata.GetMetadataForType(type),
        };
        await new EdgeBodyBinder(JsonSerializerOptions.Web).BindModelAsync(context);
        Assert.True(context.Result.IsModelSet);
        return context.Result.Model;
    }

    [Fact]
    public async Task Binds_the_parsed_body_and_never_fails_before_access_runs()
    {
        Assert.Equal(new BodyProbe("a", 2), await Bind(JsonNode.Parse("""{"name":"a","count":2}"""), typeof(BodyProbe)));
        Assert.Equal(new BodyProbe(null, 0), await Bind(null, typeof(BodyProbe)));
        Assert.Equal(new BodyProbe(null, 0), await Bind(JsonNode.Parse("""{"count":"x"}"""), typeof(BodyProbe)));
        Assert.Null(await Bind(JsonNode.Parse("[1]"), typeof(int)));
        await Assert.ThrowsAsync<ArgumentNullException>(() => new EdgeBodyBinder(JsonSerializerOptions.Web).BindModelAsync(null!));
    }

    [Fact]
    public void Serves_only_the_body_binding_source()
    {
        var services = new ServiceCollection().AddOptions().BuildServiceProvider();
        var provider = new EdgeBodyBinderProvider();
        Assert.IsType<EdgeBodyBinder>(provider.GetBinder(new ProviderContext(services, BindingSource.Body)));
        Assert.Null(provider.GetBinder(new ProviderContext(services, BindingSource.Query)));
        Assert.Throws<ArgumentNullException>(() => provider.GetBinder(null!));
    }

    private sealed class ProviderContext(IServiceProvider services, BindingSource source) : ModelBinderProviderContext
    {
        public override BindingInfo BindingInfo { get; } = new() { BindingSource = source };

        public override ModelMetadata Metadata { get; } = EdgeBodyBinderTests.Metadata.GetMetadataForType(typeof(BodyProbe));

        public override IModelMetadataProvider MetadataProvider => EdgeBodyBinderTests.Metadata;

        public override IServiceProvider Services => services;

        public override IModelBinder CreateBinder(ModelMetadata metadata) => throw new NotSupportedException();
    }
}
