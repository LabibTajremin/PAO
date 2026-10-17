using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Http.Filters;
using PAO.Infrastructure.Http.OpenApi;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Testing;

namespace PAO.Infrastructure.Http;

/// <summary>
/// The HTTP edge every API request passes, in the NestJS order: error envelope, test hooks
/// (APP_ENV=test only), client IP, request id, security headers, CORS, body, metrics,
/// operation matching (404/405) → filters (access, rate limit, validation, idempotency)
/// → controller; one exception filter answers errors.
/// </summary>
public static class HttpEdge
{
    /// <summary>Registers the contract, the filters and MVC with the edge settings.</summary>
    public static IMvcBuilder AddHttpEdge(this IServiceCollection services, string specPath)
    {
        var document = SpecDocument.Load(specPath);
        services.AddSingleton(document);
        services.AddSingleton(new SpecRoutes(document));
        services.AddSingleton(new RequestValidator(document));
        foreach (var route in HealthEndpoints.Routes)
        {
            services.AddSingleton(route);
        }
        services.AddScoped<AccessFilter>();
        services.AddScoped<RateLimitFilter>();
        services.AddScoped<RequestValidationFilter>();
        services.AddScoped<IdempotencyFilter>();
        services.AddScoped<ApiExceptionFilter>();
        return services
            .AddControllers(options =>
            {
                options.Filters.AddService<AccessFilter>();
                options.Filters.AddService<RateLimitFilter>();
                options.Filters.AddService<RequestValidationFilter>();
                options.Filters.AddService<IdempotencyFilter>();
                options.Filters.AddService<ApiExceptionFilter>();
            })
            .ConfigureApiBehaviorOptions(options => options.SuppressModelStateInvalidFilter = true);
    }

    /// <summary>Builds the pipeline.</summary>
    public static WebApplication UseHttpEdge(this WebApplication app, PaoSettings settings)
    {
        app.UseMiddleware<ErrorEnvelopeMiddleware>();
        if (settings.App.Environment == AppEnvironments.Test)
        {
            app.Use(async (context, next) =>
            {
                if (!await TestHooks.Handle(context))
                {
                    await next(context);
                }
            });
        }
        var metrics = app.Services.GetRequiredService<PaoMetrics>();
        app.Use(EdgeMiddleware.ClientAddress);
        app.Use(EdgeMiddleware.RequestId);
        app.Use(EdgeMiddleware.SecurityHeaders);
        app.Use(EdgeMiddleware.Cors(settings.App.AdminCorsOrigin));
        app.Use(EdgeMiddleware.ReadBody(settings.Http.MaxBodyBytes));
        app.Use(metrics.Record);
        app.UseMiddleware<SpecMatchMiddleware>();
        app.UseRouting();
        app.MapHealth();
        app.MapControllers();
        return app;
    }
}
