using PAO.Core.Areas.Identity.Features.AdminLogin.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Areas.Identity.Features.AdminVerifyTotp.Commands;
using PAO.Core.Areas.Identity.Features.ChangeAdminPassword.Commands;
using PAO.Core.Areas.Identity.Features.DeleteMe.Commands;
using PAO.Core.Areas.Identity.Features.GetMyPermissions.Queries;
using PAO.Core.Areas.Identity.Features.RoleEditor.Commands;
using PAO.Core.Areas.Identity.Features.RoleEditor.Queries;
using PAO.Core.Areas.Identity.Features.VerifyOtp.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.TestKit;

namespace PAO.UnitTests.Areas.Identity;

/// <summary>The Identity use cases over in-memory fakes.</summary>
public sealed class IdentityHarness
{
    public const string Phone = "01712345678";
    public const string E164 = "+8801712345678";
    public const string Email = "verifier@pao.bd";

    public IdentityHarness()
    {
        Mapper = new Mapper([new IdentityMappingProfile()]);
        Rbac = new FakeRbac(Repo);
        PhoneCodes = new PhoneCodes(Repo, Codes, Throttle, Sms);
        Accounts = new PhoneAccounts(Repo, Clock, new SequenceIds());
        Sessions = new Sessions(Repo, Families, Tokens, new SequenceIds());
        Status = new AccountStatusChanger(Repo, Sessions);
        AdminUsers = new AdminUsers(Repo, Clock, new SequenceIds());
    }

    public FakeRepository Repo { get; } = new();
    public FakeCodes Codes { get; } = new();
    public FakeThrottle Throttle { get; } = new();
    public FakeSms Sms { get; } = new();
    public FakeSessions Families { get; } = new();
    public FakeChallenges Challenges { get; } = new();
    public FakeTokens Tokens { get; } = new();
    public FakeLevels Levels { get; } = new();
    public FakeRbac Rbac { get; }
    public FakeClock Clock { get; } = new(DateTimeOffset.Parse("2026-10-09T10:00:00Z", System.Globalization.CultureInfo.InvariantCulture));
    public IMapper Mapper { get; }
    public PhoneCodes PhoneCodes { get; }
    public PhoneAccounts Accounts { get; }
    public Sessions Sessions { get; }
    public AccountStatusChanger Status { get; }
    public AdminUsers AdminUsers { get; }

    public VerifyOtpHandler SignIn => new(PhoneCodes, Accounts, Sessions, Mapper);
    public GetMyPermissionsHandler Permissions => new(Repo, Rbac, Levels, Mapper);
    public DeleteMeHandler Deletion => new(Repo, PhoneCodes, Sessions);
    public AdminLoginHandler AdminLogin => new(Repo, Challenges, Clock, new SequenceIds(), Mapper);
    public AdminVerifyTotpHandler AdminTotp => new(Repo, Challenges, Sessions, Clock, Mapper);
    public ChangeAdminPasswordHandler ChangePassword => new(Repo);
    public UpdateAdminUserHandler UpdateAdmin => new(Repo, Sessions, Mapper);
    public ListRolesHandler ListRoles => new(Repo, Mapper);
    public UpdateRoleHandler UpdateRole => new(Repo, Rbac, Mapper);

    /// <summary>The code in the newest SMS.</summary>
    public string SentCode() => Sms.Last.Split("code: ")[1][..6];

    /// <summary>Signs in through `app` with a fresh code.</summary>
    public async Task<TokenPairView> Login(string app)
    {
        await PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        return await SignIn.Handle(new VerifyOtpCommand(Phone, SentCode(), app), CancellationToken.None);
    }

    /// <summary>The caller of the newest session of the account.</summary>
    public Caller CallerOf(TokenPairView session)
    {
        var id = Guid.Parse(session.Account.Id);
        var family = Families.Families.Values.Last(f => f.AccountId == id);
        return new Caller(id, family.Id, family.AccessTokenId, family.AccessExpiresAt);
    }

    public Task<InvitedAdmin> NewAdmin() => AdminUsers.Create(Email, "V", [Roles.Verifier], CancellationToken.None);

    public static async Task<object?> Outcome(Func<Task> call)
    {
        try
        {
            await call();
            return "resolved";
        }
        catch (DomainException error)
        {
            return error.Reason;
        }
        catch (Exception error)
        {
            return error;
        }
    }

    public string Totp(string secret) => PAO.Infrastructure.Crypto.Totp.Code(secret, Clock.Now);

    public static AdminLoginRequest LoginRequest(string email, string password) => new(email, password);

    public static AdminVerifyTotpCommand TotpCommand(Guid challengeId, string code) => new(challengeId.ToString(), code);

    public static ChangeAdminPasswordCommand PasswordChange(Guid id, string current, string next) => new(id, current, next);

    public static DeleteMeCommand Delete(Caller caller, string code) => new(caller.AccountId, code);

    public static UpdateRoleCommand Role(string role, string[] permissions, string[] screens) => new(role, permissions, screens);

    public static ListRolesQuery RolesQuery => new();

    public static GetMyPermissionsQuery PermissionsOf(string id) => new(Guid.Parse(id));

    public static UpdateAdminUserCommand Update(Guid id, IReadOnlyList<string>? roles, bool? active) => new(id, roles, active);

    public static string Hash(string secret) => SecretHasher.Hash(secret, Argon2Params.Code).Result;
}
