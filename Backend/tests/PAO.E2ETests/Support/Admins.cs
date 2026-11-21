using OtpNet;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Support;

/// <summary>
/// Seeded admins signed in with password and authenticator code. TOTP enrolment happens
/// only on an admin's first sign-in, so the secrets are kept across runs against one stack
/// in .admins.env (stack.sh removes it); sessions are reused for the rest of the run.
/// </summary>
public static class Admins
{
    private static readonly Dictionary<string, Session> Sessions = [];
    private static readonly SemaphoreSlim Gate = new(1, 1);

    private static string SecretsFile => Path.Combine(Stack.StateDir, ".admins.env");

    /// <summary>The RFC 6238 code (SHA-1, 30 s, 6 digits) an authenticator app shows at `at`.</summary>
    public static string Totp(string secret, DateTimeOffset at) =>
        new Totp(Base32Encoding.ToBytes(secret)).ComputeTotp(at.UtcDateTime);

    /// <summary>Time until one second into the next 30-second TOTP step.</summary>
    public static TimeSpan UntilNextStep(DateTimeOffset now) =>
        TimeSpan.FromMilliseconds(30_000 - (now.ToUnixTimeMilliseconds() % 30_000) + 1000);

    public static async Task<Session> Admin(string email)
    {
        await Gate.WaitAsync();
        try
        {
            if (!Sessions.TryGetValue(email, out var known))
            {
                known = new Session(Token: await SignInAdmin(email));
                Sessions[email] = known;
            }
            return known;
        }
        finally
        {
            Gate.Release();
        }
    }

    private static async Task<(string Secret, string Challenge)> SecretAndChallenge(string email)
    {
        var ch = (await Send("POST", "/v1/auth/admin/login", new { email, password = Stack.Current.AdminPassword })).Expect(200);
        var secret = Stack.ReadEnv(SecretsFile).GetValueOrDefault(email, string.Empty);
        if (ch["totpEnrolment"] is { } enrolment)
        {
            secret = Str(Obj(enrolment)["secret"]);
            Directory.CreateDirectory(Stack.StateDir);
            await File.AppendAllTextAsync(SecretsFile, $"{email}={secret}\n");
        }
        return (secret, Str(ch["challengeId"]));
    }

    private static async Task<string> SignInAdmin(string email)
    {
        var (secret, challenge) = await SecretAndChallenge(email);
        Task<Reply> Enter() => Send("POST", "/v1/auth/admin/totp", new { challengeId = challenge, code = Totp(secret, DateTimeOffset.UtcNow) });
        var r = await Enter();
        if (r.Status != 200)
        {
            // A code is accepted once; a run right after the last one waits for the next.
            await Task.Delay(UntilNextStep(DateTimeOffset.UtcNow));
            r = await Enter();
        }
        if (r.Status != 200)
        {
            throw new InvalidOperationException($"admin {email} totp: {r.Status} {r.Body}");
        }
        return Str(r.Json()["accessToken"]);
    }
}
