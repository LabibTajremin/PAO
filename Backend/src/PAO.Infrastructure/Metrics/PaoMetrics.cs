using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using PAO.Infrastructure.Http.Edge;
using Prometheus;

namespace PAO.Infrastructure.Metrics;

/// <summary>
/// Prometheus metrics for requests, errors and latency (PRD §11), with the established metric
/// names so dashboards and alerts carry over. The registry belongs to the instance, so
/// nothing is registered globally and tests stay independent.
/// </summary>
public sealed class PaoMetrics
{
    private readonly Counter requests;
    private readonly Histogram latency;

    /// <summary>Creates the registry with the HTTP, worker and .NET runtime metrics.</summary>
    public PaoMetrics()
    {
        Registry = Prometheus.Metrics.NewCustomRegistry();
        var factory = Prometheus.Metrics.WithCustomRegistry(Registry);
        requests = factory.CreateCounter("pao_http_requests_total", "HTTP requests by route, method and status.", "route", "method", "status");
        latency = factory.CreateHistogram("pao_http_request_duration_seconds", "HTTP request latency by route.", new HistogramConfiguration
        {
            LabelNames = ["route", "method"],
            Buckets = [0.01, 0.025, 0.05, 0.1, 0.2, 0.3, 0.5, 1, 2, 5],
        });
        Worker = new WorkerMetrics(Registry, factory);
        DotNetStats.Register(Registry);
    }

    /// <summary>The registry /metrics renders.</summary>
    public CollectorRegistry Registry { get; }

    /// <summary>Job and outbox metrics; only the worker records them.</summary>
    public WorkerMetrics Worker { get; }

    /// <summary>
    /// Records each request under its route template, so ids in paths do not explode label
    /// cardinality; unmatched requests count as `unmatched`.
    /// </summary>
    public async Task Record(HttpContext context, RequestDelegate next)
    {
        var started = Stopwatch.GetTimestamp();
        try
        {
            await next(context);
        }
        finally
        {
            var route = context.Edge().RouteTemplate ?? "unmatched";
            var method = context.Request.Method;
            requests.WithLabels(route, method, context.Response.StatusCode.ToString(System.Globalization.CultureInfo.InvariantCulture)).Inc();
            latency.WithLabels(route, method).Observe(Stopwatch.GetElapsedTime(started).TotalSeconds);
        }
    }

    /// <summary>Renders the registry in the Prometheus text format.</summary>
    public async Task Render(HttpContext context)
    {
        context.Response.ContentType = PrometheusConstants.ExporterContentTypeValue.ToString();
        await Registry.CollectAndExportAsTextAsync(context.Response.Body, context.RequestAborted);
    }
}
