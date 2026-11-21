using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Filters;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Redis;

namespace PAO.Infrastructure.Http.Filters;

/// <summary>
/// Replays the first answer for a repeated `Idempotency-Key` on operations that declare the
/// header (PRD §9.6). Answers below 500, errors included, are stored for 24 hours; a server
/// error or an aborted request frees the key so the client can retry.
/// The answer is buffered and stored before any byte reaches the client: storing it after
/// the response (Response.OnCompleted) let a client that retried at once find the key still
/// running and get 409 IDEMPOTENCY_IN_PROGRESS instead of the replay (ADR-0036).
/// Registered scoped, so one instance serves both stages of a request.
/// </summary>
public sealed class IdempotencyFilter(IdempotencyStore store, RedisKeys keys) : IAsyncActionFilter, IAsyncAlwaysRunResultFilter
{
    private Pending? pending;

    /// <summary>Fingerprints a request: method, path and body, so a reused key with another body is caught.</summary>
    public static string RequestHash(string method, string path, byte[] body) =>
        Convert.ToHexStringLower(SHA256.HashData([.. Encoding.UTF8.GetBytes($"{method} {path}\n"), .. body]));

    /// <inheritdoc />
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var http = context.HttpContext;
        var edge = http.Edge();
        var idempotencyKey = http.Request.Headers["Idempotency-Key"];
        if (edge.Operation?.Operation.Idempotent == true && edge.Principal is { } principal && idempotencyKey.Count == 1)
        {
            var key = keys.Key("idem", principal.AccountId.ToString(), idempotencyKey.ToString());
            var hash = RequestHash(http.Request.Method, http.Request.Path.Value ?? "/", edge.RawBody);
            await Claim(key, hash);
            // The exception filter writes errors during this stage, so the buffer goes in now.
            pending = new Pending(key, hash, http.Response.Body, new MemoryStream());
            http.Response.Body = pending.Buffer;
        }
        await next();
    }

    /// <inheritdoc />
    public async Task OnResultExecutionAsync(ResultExecutingContext context, ResultExecutionDelegate next)
    {
        if (pending is not { } p)
        {
            await next();
            return;
        }
        var http = context.HttpContext;
        var written = false;
        try
        {
            await next();
            written = true;
        }
        finally
        {
            http.Response.Body = p.Original;
            await Record(http, p, written);
        }
        p.Buffer.Position = 0;
        await p.Buffer.CopyToAsync(p.Original, http.RequestAborted);
    }

    private async Task Record(HttpContext http, Pending p, bool written)
    {
        if (!written || http.RequestAborted.IsCancellationRequested || http.Response.StatusCode >= 500)
        {
            await store.Release(p.Key);
            return;
        }
        await store.Complete(p.Key, p.Hash, http.Response.StatusCode, p.Buffer.ToArray());
    }

    private async Task Claim(string key, string hash)
    {
        var (reserved, record) = await store.Reserve(key, hash);
        if (reserved)
        {
            return;
        }
        if (record.RequestHash != hash)
        {
            throw ApiErrors.IdempotencyKeyReused;
        }
        if (!record.Done)
        {
            throw ApiErrors.IdempotencyInProgress;
        }
        throw new StoredResponseException(record.Status == 0 ? 200 : record.Status, record.Body ?? []);
    }

    private sealed record Pending(string Key, string Hash, Stream Original, MemoryStream Buffer);
}
