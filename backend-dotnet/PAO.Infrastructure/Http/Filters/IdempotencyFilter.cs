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
/// </summary>
public sealed class IdempotencyFilter(IdempotencyStore store, RedisKeys keys) : IAsyncActionFilter
{
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
            Remember(http, key, hash);
        }
        await next();
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

    // Records the answer as it is written, whichever layer writes it (action or exception filter).
    private void Remember(HttpContext http, string key, string hash)
    {
        var copy = new MemoryStream();
        http.Response.Body = new TeeStream(http.Response.Body, copy);
        http.Response.OnCompleted(async () =>
        {
            // A failure here is logged by the server; the key then expires on its own.
            if (http.RequestAborted.IsCancellationRequested || http.Response.StatusCode >= 500)
            {
                await store.Release(key);
            }
            else
            {
                await store.Complete(key, hash, http.Response.StatusCode, copy.ToArray());
            }
        });
    }
}
