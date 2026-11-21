using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace PAO.Infrastructure.Http.Edge;

/// <summary>
/// Binds every <c>[FromBody]</c> parameter from the JSON the edge already parsed, and never
/// fails. MVC binds before action filters run, and its own body binder answers 415 or 400 to a
/// missing or wrong body there, ahead of the access filter. Earlier releases authenticated and
/// authorised first, so a body problem must not surface until request validation, which runs
/// after access and reports <see cref="EdgeState.BodyError"/> and schema errors as 422.
/// </summary>
public sealed class EdgeBodyBinder(JsonSerializerOptions json) : IModelBinder
{
    /// <inheritdoc />
    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        ArgumentNullException.ThrowIfNull(bindingContext);
        var body = bindingContext.HttpContext.Edge().Body;
        var model = Read(body, bindingContext.ModelType) ?? Read(new JsonObject(), bindingContext.ModelType);
        bindingContext.Result = ModelBindingResult.Success(model);
        return Task.CompletedTask;
    }

    // A body of the wrong shape becomes the empty model: validation rejects it before the action runs.
    private object? Read(JsonNode? body, Type type)
    {
        try
        {
            return body?.Deserialize(type, json);
        }
        catch (JsonException)
        {
            return null;
        }
    }
}

/// <summary>Routes the body binding source to <see cref="EdgeBodyBinder"/>.</summary>
public sealed class EdgeBodyBinderProvider : IModelBinderProvider
{
    /// <inheritdoc />
    public IModelBinder? GetBinder(ModelBinderProviderContext context)
    {
        ArgumentNullException.ThrowIfNull(context);
        if (context.BindingInfo.BindingSource != BindingSource.Body)
        {
            return null;
        }
        var json = context.Services.GetRequiredService<IOptions<JsonOptions>>().Value.JsonSerializerOptions;
        return new EdgeBodyBinder(json);
    }
}
