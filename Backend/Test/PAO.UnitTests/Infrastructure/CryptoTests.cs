using System.Text;
using Microsoft.AspNetCore.WebUtilities;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Crypto;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class TokenTests
{
    // Signed by the NestJS backend (jose) with the seed TestEnvironment.Key, kid k1.
    private const string NestToken =
        "eyJhbGciOiJFZERTQSIsImtpZCI6ImsxIiwidHlwIjoiSldUIn0.eyJyb2xlcyI6WyJjdXN0b21lciJdLCJ2ZXIiOjMsInNpZCI6IjAxOTBhNWIyLTdjMWQtN2UzZi04YTliLTBjMWQyZTNmNGE1YiIsImlzcyI6InBhbyIsInN1YiI6IjAxOTBhNWIyLTdjMWQtN2UzZi04YTliLTBjMWQyZTNmNGE1YyIsImV4cCI6NDEwMjQ0NDgwMCwiaWF0IjoxNzYwMDAwMDAwLCJqdGkiOiIwMTkwYTViMi03YzFkLTdlM2YtOGE5Yi0wYzFkMmUzZjRhNWQifQ.yLc5awwrBwCGHtDSJ-LGpyP8RuQzvYhtbomDsyx-QiDeF7Q1twt-nqcgtdWu2nnyYtSm6A8qqtJvWw5t1Fn5CA";

    private static readonly DateTimeOffset IssuedAt = DateTimeOffset.FromUnixTimeSeconds(1760000000);
    private static readonly JwtKeyRing Ring = JwtKeyRing.From(new JwtOptions { SigningKey = TestEnvironment.Key, AccessTokenTtlSeconds = 900 });

    private static TokenVerifier Verifier(DateTimeOffset now) => new(Ring.VerificationKeys, new FakeClock(now));

    [Fact]
    public void Signs_byte_for_byte_what_the_nestjs_backend_signed()
    {
        var signing = Ring.Signing with { Ttl = TimeSpan.FromSeconds(4102444800 - 1760000000) };
        var signer = new TokenSigner(signing, new FakeClock(IssuedAt), new SequenceIds(Guid.Parse("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5d")));
        var (token, claims) = signer.Sign(new TokenRequest("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c", ["customer"], "0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5b", 3));
        Assert.Equal(NestToken, token);
        Assert.Equal(3, claims.Version);
    }

    [Fact]
    public void Verifies_nestjs_tokens()
    {
        var claims = Verifier(IssuedAt).Verify(NestToken);
        Assert.Equal("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c", claims.Subject);
        Assert.Equal(["customer"], claims.Roles);
        Assert.Equal("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5b", claims.SessionId);
        Assert.Equal("0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5d", claims.TokenId);
        Assert.Equal(3, claims.Version);
        Assert.Equal(4102444800, claims.ExpiresAt.ToUnixTimeSeconds());
    }

    [Fact]
    public void Round_trips_with_defaults_and_expires()
    {
        var signer = new TokenSigner(Ring.Signing, new FakeClock(IssuedAt), new SequenceIds());
        var (token, claims) = signer.Sign(new TokenRequest(Guid.NewGuid().ToString(), ["provider", "customer"]));
        Assert.Equal(UuidText.Nil, Verifier(IssuedAt).Verify(token).SessionId);
        Assert.Equal(IssuedAt.AddMinutes(15), claims.ExpiresAt);
        Assert.Throws<TokenExpiredException>(() => Verifier(IssuedAt.AddMinutes(15)).Verify(token));
    }

    private static string Forge(string header, string payload, string? signature = null)
    {
        var h = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(header));
        var p = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(payload));
        var sig = signature ?? WebEncoders.Base64UrlEncode(Ed25519Keys.Sign(Ring.Signing.Key, Encoding.ASCII.GetBytes($"{h}.{p}")));
        return $"{h}.{p}.{sig}";
    }

    private const string Header = """{"alg":"EdDSA","kid":"k1"}""";
    private const string Sub = "0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c";

    public static TheoryData<string> InvalidTokens() =>
    [
        "a.b",
        "!!!.e30.e30",
        Forge("[]", "{}"),
        Forge("not json", "{}"),
        Forge("""{"alg":"HS256","kid":"k1"}""", "{}"),
        Forge("""{"alg":"EdDSA","kid":"k1","crit":["x"]}""", "{}"),
        Forge("""{"alg":"EdDSA","kid":"k9"}""", "{}"),
        Forge("""{"alg":"EdDSA"}""", "{}"),
        Forge(Header, "{}", "AAAA"),
        Forge(Header, """{"iss":"pao"}"""),
        Forge(Header, """{"exp":4102444800,"iss":"other"}"""),
        Forge(Header, """{"exp":4102444800,"iss":"pao","iat":"x"}"""),
        Forge(Header, """{"exp":4102444800,"iss":"pao","nbf":"x"}"""),
        Forge(Header, """{"exp":4102444800,"iss":"pao","nbf":4102444000}"""),
        Forge(Header, """{"exp":"soon","iss":"pao"}"""),
        Forge(Header, $$"""{"exp":4102444800,"iss":"pao","sub":"nope","roles":[]}"""),
        Forge(Header, $$"""{"exp":4102444800,"iss":"pao","sub":"{{Sub}}"}"""),
        Forge(Header, $$"""{"exp":4102444800,"iss":"pao","sub":"{{Sub}}","roles":"x"}"""),
        Forge(Header, $$"""{"exp":4102444800,"iss":"pao","sub":"{{Sub}}","roles":[1]}"""),
        Forge(Header, $$"""{"exp":4102444800,"iss":"pao","sub":"{{Sub}}","roles":[],"sid":5}"""),
    ];

    [Theory]
    [MemberData(nameof(InvalidTokens))]
    public void Rejects_forged_and_malformed_tokens(string token)
    {
        Assert.Throws<TokenInvalidException>(() => Verifier(IssuedAt).Verify(token));
    }

    [Fact]
    public void Accepts_optional_claims_in_their_valid_forms()
    {
        var claims = Verifier(IssuedAt).Verify(Forge(Header, $$"""{"exp":4102444800,"iss":"pao","iat":1,"nbf":1,"sub":"{{Sub}}","roles":[],"ver":"x"}"""));
        Assert.Equal(0, claims.Version);
        Assert.Equal(string.Empty, claims.TokenId);
    }

    [Fact]
    public void Previous_keys_still_verify_and_bad_keys_fail_the_ring()
    {
        var old = Ed25519Keys.FromSeed(new byte[32]);
        var ring = JwtKeyRing.From(new JwtOptions
        {
            SigningKey = TestEnvironment.Key,
            KeyId = "k2",
            PreviousPublicKeys = "k1:" + Convert.ToBase64String(Ring.VerificationKeys["k1"].GetEncoded()),
        });
        Assert.Equal(["k1", "k2"], ring.VerificationKeys.Keys.Order());
        Assert.NotNull(new TokenVerifier(ring.VerificationKeys, new FakeClock(IssuedAt)).Verify(NestToken));
        Assert.Throws<ConfigException>(() => JwtKeyRing.From(new JwtOptions { SigningKey = "x" }));
        Assert.Throws<ConfigException>(() => JwtKeyRing.From(new JwtOptions { SigningKey = TestEnvironment.Key, PreviousPublicKeys = "bad" }));
        Assert.Throws<ArgumentException>(() => Ed25519Keys.FromRaw(new byte[3]));
        Assert.False(Ed25519Keys.Verify(old.GeneratePublicKey(), [1], Ed25519Keys.Sign(old, [2])));
    }

    [Fact]
    public void Uuid_text_follows_the_uuid_package()
    {
        Assert.True(UuidText.IsValid(UuidText.Nil));
        Assert.True(UuidText.IsValid("FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"));
        Assert.False(UuidText.IsValid("0190a5b2-7c1d-9e3f-8a9b-0c1d2e3f4a5c"));
        Assert.False(UuidText.IsValid(null));
    }
}

public sealed class SecretTests
{
    private const string NestHash = "$argon2id$v=19$m=8192,t=1,p=1$MDEyMzQ1Njc4OWFiY2RlZg$64zw4y6hGNSGW1HTKDajc74EIkJpCJ+AUBXDspyrFEU";

    [Fact]
    public async Task Verifies_hashes_the_nestjs_backend_stored()
    {
        Assert.True(await SecretHasher.Verify("correct horse", NestHash));
        Assert.False(await SecretHasher.Verify("wrong horse", NestHash));
    }

    [Fact]
    public async Task Hashes_in_phc_format_and_verifies_its_own()
    {
        var hash = await SecretHasher.Hash("123456", Argon2Params.Code);
        Assert.StartsWith("$argon2id$v=19$m=8192,t=1,p=1$", hash, StringComparison.Ordinal);
        Assert.True(await SecretHasher.Verify("123456", hash));
        Assert.Equal(65536, Argon2Params.Password.Memory);
    }

    [Theory]
    [InlineData("plain")]
    [InlineData("$argon2i$v=19$m=8,t=1,p=1$AAAA$AAAA")]
    [InlineData("$argon2id$v=19$m=x$AAAA$AAAA")]
    [InlineData("$argon2id$v=19$m=8,t=1,p=1$A$AAAA")]
    [InlineData("$argon2id$v=19$m=8,t=1,p=1$AAAA$!!")]
    public async Task Rejects_malformed_hashes(string encoded)
    {
        await Assert.ThrowsAsync<HashMalformedException>(() => SecretHasher.Verify("x", encoded));
    }

    [Fact]
    public void Decrypts_nestjs_ciphertext_and_derives_the_same_lookup_hash()
    {
        var cipher = new DataCipher(Convert.FromBase64String(TestEnvironment.Key));
        var nest = Convert.FromBase64String("AAECAwQFBgcICQoLHNeISOwu5ZSR7Bn/B7vQuMV0MaUshRGTavg=");
        Assert.Equal("1234567890", Encoding.UTF8.GetString(cipher.Decrypt(nest)));
        Assert.Equal("97d811976eaf1b37a0061847940e10d0cd859b123de7c3b3c78fb786f865f06b", cipher.LookupHash("1234567890"));
        Assert.Equal("x", Encoding.UTF8.GetString(cipher.Decrypt(cipher.Encrypt("x"u8.ToArray()))));
        nest[^1] ^= 1;
        Assert.Throws<CiphertextException>(() => cipher.Decrypt(nest));
        Assert.Throws<CiphertextException>(() => cipher.Decrypt(new byte[10]));
        Assert.Throws<ArgumentException>(() => new DataCipher(new byte[5]));
    }

    [Fact]
    public void Totp_codes_match_otplib_with_one_step_of_drift()
    {
        const string secret = "JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP";
        var at = DateTimeOffset.FromUnixTimeSeconds(1760000000);
        Assert.Equal("325812", Totp.Code(secret, at));
        Assert.True(Totp.Validate("325812", secret, at.AddSeconds(30)));
        Assert.False(Totp.Validate("325812", secret, at.AddSeconds(90)));
        Assert.False(Totp.Validate("32581", secret, at));
        Assert.False(Totp.Validate("32581x", secret, at));
        Assert.False(Totp.Validate("325812", "!!!", at));
        Assert.False(Totp.Validate("325812", string.Empty, at));
        Assert.Throws<ArgumentException>(() => Totp.Code("!!!", at));
    }

    [Fact]
    public void New_totp_secrets_come_with_an_otpauth_url()
    {
        var enrolment = Totp.NewSecret("ops(1)@pao.test");
        Assert.Equal(32, enrolment.Secret.Length);
        Assert.Equal($"otpauth://totp/PAO:ops(1)@pao.test?algorithm=SHA1&digits=6&issuer=PAO&period=30&secret={enrolment.Secret}", enrolment.Url);
        Assert.Throws<ArgumentException>(() => Totp.NewSecret(string.Empty));
    }

    [Fact]
    public void Random_secrets_have_the_requested_shape()
    {
        Assert.Equal(43, RandomSecrets.Token(32).Length);
        Assert.Matches("^[0-9]{6}$", RandomSecrets.Digits(6));
        Assert.Equal("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824", RandomSecrets.Sha256Hex("hello"));
    }
}
