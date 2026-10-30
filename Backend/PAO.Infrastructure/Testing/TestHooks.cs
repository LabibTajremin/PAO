using System.Globalization;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using PAO.Lib.Areas.Identity;

namespace PAO.Infrastructure.Testing;

/// <summary>What the capturing SMS adapter recorded; registered when APP_ENV=test.</summary>
public interface ISmsCapture
{
    /// <summary>The newest message texted to `phone` (E.164), if any.</summary>
    string? Last(string phone);
}

/// <summary>A push notification as the capture adapter recorded it.</summary>
public sealed record CapturedPush(string Title, string Body, IReadOnlyDictionary<string, string> Data);

/// <summary>What the capturing push adapter recorded; registered unless PUSH_ADAPTER=fcm.</summary>
public interface IPushCapture
{
    /// <summary>The pushes sent to `deviceToken`, oldest first.</summary>
    IReadOnlyList<CapturedPush> SentTo(string deviceToken);
}

/// <summary>Runs the document-expiry sweep at a chosen time; the Verification area provides it.</summary>
public interface IDocumentExpiry
{
    /// <summary>Expires what is due at `at`.</summary>
    Task ExpireDocumentsAt(DateTimeOffset at, CancellationToken cancellationToken);
}

/// <summary>
/// The `/__test/` endpoints the end-to-end journeys use to read the one-time codes and
/// pushes the fake adapters captured and to run the expiry sweep on demand. Hosts mount
/// them only when APP_ENV=test, so they never exist in production.
/// </summary>
public static partial class TestHooks
{
    /// <summary>Answers a test-hook request and reports whether `context` was one.</summary>
    public static async Task<bool> Handle(HttpContext context)
    {
        var request = context.Request;
        var services = context.RequestServices;
        switch ($"{request.Method} {request.Path.Value}")
        {
            case "GET /__test/sms":
                await LastSms(context, services.GetService<ISmsCapture>());
                return true;
            case "GET /__test/pushes":
                var pushes = services.GetService<IPushCapture>()?.SentTo(request.Query["token"].ToString()) ?? [];
                await context.Response.WriteAsJsonAsync(new { pushes });
                return true;
            case "POST /__test/verification/expire":
                await ExpireDocuments(context, services.GetService<IDocumentExpiry>());
                return true;
            default:
                return false;
        }
    }

    private static async Task LastSms(HttpContext context, ISmsCapture? sms)
    {
        var phone = PhoneNumber.Normalize(context.Request.Query["phone"].ToString());
        if (sms is not null && phone is null)
        {
            await Text(context, 400, "bad phone");
            return;
        }
        var message = phone is null ? null : sms?.Last(phone);
        if (message is null)
        {
            await Text(context, 404, "404 page not found");
            return;
        }
        await context.Response.WriteAsJsonAsync(new { message });
    }

    private static async Task ExpireDocuments(HttpContext context, IDocumentExpiry? expiry)
    {
        var at = context.Request.Query["at"].ToString();
        if (!Rfc3339().IsMatch(at) || !DateTimeOffset.TryParse(at, CultureInfo.InvariantCulture, DateTimeStyles.None, out var when))
        {
            await Text(context, 400, "at must be RFC 3339");
            return;
        }
        if (expiry is null)
        {
            await Text(context, 501, "document expiry is not wired");
            return;
        }
        await expiry.ExpireDocumentsAt(when, context.RequestAborted);
        context.Response.StatusCode = 204;
    }

    private static Task Text(HttpContext context, int status, string text)
    {
        context.Response.StatusCode = status;
        context.Response.ContentType = "text/plain; charset=utf-8";
        return context.Response.WriteAsync(text + "\n");
    }

    [GeneratedRegex(@"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$", RegexOptions.IgnoreCase)]
    private static partial Regex Rfc3339();
}
