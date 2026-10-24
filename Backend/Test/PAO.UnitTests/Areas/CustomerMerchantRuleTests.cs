using System.Text.Json;
using PAO.Core.Areas.Customer.Services;
using PAO.Core.Areas.Merchant.Services;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Migrator;

namespace PAO.UnitTests.Areas;

public sealed class CustomerRuleTests
{
    private static readonly GeoPoint Banani = new() { Lat = 23.7937, Lng = 90.4066 };

    [Theory]
    [InlineData("N", "bn")]
    [InlineData("Nusrat", "fr")]
    public void Refuses_bad_profiles(string name, string language) =>
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.ProfileProblem(name, language));

    [Fact]
    public void Accepts_bangla_names_and_counts_code_points()
    {
        Assert.Null(CustomerRules.ProfileProblem("নুসরাত", "bn"));
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.ProfileProblem(new string('ন', 81), "bn"));
    }

    [Fact]
    public void Checks_addresses_and_the_country_box()
    {
        Assert.Null(CustomerRules.AddressProblem("home", "House 12, Road 5", "", "", Banani));
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.AddressProblem("farm", "House 12", "", "", Banani));
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.AddressProblem("home", "ab", "", "", Banani));
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.AddressProblem("home", "House", new string('x', 201), "", Banani));
        Assert.Equal(CustomerReasons.Invalid, CustomerRules.AddressProblem("home", "House", "", new string('x', 81), Banani));
        var swapped = new GeoPoint { Lat = Banani.Lng, Lng = Banani.Lat };
        Assert.Equal(CustomerReasons.OutsideCountry, CustomerRules.AddressProblem("home", "House", "", "", swapped));
        Assert.Equal(["home", "office", "other"], CustomerRules.AddressLabels);
        CustomerRules.Check(null);
        Assert.Equal("x", Assert.Throws<DomainException>(() => CustomerRules.Check("x")).Reason);
    }

    private const string Square = """{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,24],[90,23]],[[90.5,23.5],[90.6,23.5],[90.6,23.6],[90.5,23.6],[90.5,23.5]]]}""";
    private const string Multi = """{"type":"MultiPolygon","coordinates":[[[[88,22],[89,22],[89,23],[88,22]]],[[[90,23],[91,23],[91,24],[90,24],[90,23]]]]}""";

    public static TheoryData<string, double, double, bool> Areas() => new()
    {
        { "", 23.7937, 90.4066, true },
        { Square, 23.7937, 90.4066, true },
        { Square, 23.55, 90.55, false },
        { Square, 22, 90.5, false },
        { Multi, 23.7937, 90.4066, true },
        { """{"type":"Polygon","coordinates":[]}""", 23.79, 90.4, false },
        { """{"type":"Point","coordinates":[90,23]}""", 23.79, 90.4, false },
        { """{"type":"Polygon"}""", 23.79, 90.4, false },
        { """{"type":"Polygon","coordinates":[[[90,23],[91]]]}""", 23.79, 90.4, false },
        { """{"type":"Polygon","coordinates":[[1]]}""", 23.79, 90.4, false },
        { "[]", 23.79, 90.4, false },
        { "{", 23.79, 90.4, false },
    };

    [Theory]
    [MemberData(nameof(Areas))]
    public void Tests_the_launch_area(string area, double lat, double lng, bool covered) =>
        Assert.Equal(covered, LaunchArea.Covers(area, new GeoPoint { Lat = lat, Lng = lng }));

    [Fact]
    public void Escapes_like_patterns()
    {
        Assert.Equal(string.Empty, SqlLike.Contains("  "));
        Assert.Equal(@"%rahim\_\%\\%", SqlLike.Contains(@" RAHIM_%\ "));
    }

    [Fact]
    public void Reads_string_arrays_from_payloads()
    {
        var envelope = new Envelope
        {
            Id = Guid.NewGuid(),
            Module = "m",
            Name = "n",
            AggregateId = "a",
            OccurredAt = DateTimeOffset.UtcNow,
            Payload = JsonDocument.Parse("""{"roles":["customer",1],"bad":"x"}""").RootElement,
        };
        var p = new EventPayload(envelope);
        Assert.Equal(["customer"], p.Texts("roles"));
        Assert.Empty(p.Texts("missing"));
        Assert.Throws<FormatException>(() => p.Texts("bad"));
    }
}

public sealed class MerchantRuleTests
{
    private static readonly DateOnly Today = new(2026, 10, 9);

    private static PersonalInfoInput Personal() => new()
    {
        FullName = "Rahim Uddin",
        DateOfBirth = new DateOnly(2008, 10, 9),
        Gender = "male",
        PresentAddress = "Banani 11",
        PermanentAddress = "Cumilla Sadar",
    };

    [Fact]
    public void Tracks_progress_with_skill_proof_optional()
    {
        var empty = EnrolmentRules.Progress([]);
        Assert.False(empty.Complete);
        Assert.Equal(9, empty.Steps.Count);
        Assert.False(empty.Steps[6].Required);
        IReadOnlyList<string> done = [];
        foreach (var s in EnrolmentRules.Steps.Where(s => s != EnrolmentStep.SkillProof))
        {
            done = EnrolmentRules.WithStep(done, s);
        }
        done = EnrolmentRules.WithStep(done, EnrolmentStep.Personal);
        Assert.Equal(8, done.Count);
        var full = EnrolmentRules.Progress([.. done], true);
        Assert.True(full.Complete && full.Submitted);
        Assert.Equal(7, EnrolmentRules.WithoutStep(done, EnrolmentStep.Personal).Count);
    }

    [Fact]
    public void Validates_the_personal_step_against_the_18th_birthday()
    {
        Assert.Null(EnrolmentRules.PersonalProblem(Personal(), Today));
        Assert.Equal(MerchantReasons.TooYoung, EnrolmentRules.PersonalProblem(Personal() with { DateOfBirth = new DateOnly(2008, 10, 10) }, Today));
        Assert.Equal(MerchantReasons.Invalid, EnrolmentRules.PersonalProblem(Personal() with { Gender = "x" }, Today));
        Assert.Equal(MerchantReasons.Invalid, EnrolmentRules.PersonalProblem(Personal() with { Bio = new string('b', 501) }, Today));
        Assert.Equal(new DateOnly(2026, 10, 12), DhakaDates.Today(new DateTimeOffset(2026, 10, 11, 18, 30, 0, TimeSpan.Zero)));
        Assert.Equal(new DateOnly(2026, 10, 11), DhakaDates.Today(new DateTimeOffset(2026, 10, 11, 17, 59, 0, TimeSpan.Zero)));
    }

    [Fact]
    public void Validates_services_area_and_contact()
    {
        Assert.False(EnrolmentRules.ServicesValid(0, 1));
        Assert.False(EnrolmentRules.ServicesValid(6, 1));
        Assert.False(EnrolmentRules.ServicesValid(1, 61));
        Assert.True(EnrolmentRules.ServicesValid(5, 0));
        var dhaka = new GeoPoint { Lat = 23.8, Lng = 90.4 };
        Assert.False(EnrolmentRules.AreaValid(dhaka, 999));
        Assert.False(EnrolmentRules.AreaValid(new GeoPoint { Lat = 90.4, Lng = 23.8 }, 5000));
        Assert.True(EnrolmentRules.AreaValid(dhaka, 30000));
        var e = new EmergencyContact { Name = "Karim", Relation = "Brother", Phone = "+8801712345679" };
        Assert.True(EnrolmentRules.ContactValid(e, "+8801712345678"));
        Assert.False(EnrolmentRules.ContactValid(e, e.Phone));
        Assert.False(EnrolmentRules.ContactValid(e with { Name = "K", Phone = "" }, ""));
    }

    [Fact]
    public void Lets_only_active_verified_merchants_with_an_area_go_online()
    {
        var ready = new StoredMerchant { Id = Guid.NewGuid(), Level = 1, HomeBase = new GeoPoint { Lat = 0, Lng = 0 }, ServiceIds = [Guid.NewGuid()] };
        Assert.Null(MerchantRules.CannotGoOnline(ready));
        Assert.Equal(MerchantReasons.NotVerified, MerchantRules.CannotGoOnline(ready with { AccountStatus = "suspended", Level = 2 }));
        Assert.Equal(MerchantReasons.NoServiceArea, MerchantRules.CannotGoOnline(ready with { HomeBase = null }));
        Assert.Equal(MerchantReasons.NoServiceArea, MerchantRules.CannotGoOnline(ready with { ServiceIds = [] }));
        Assert.Equal(["none", "verified", "verified_pro"], new[] { 0, 1, 2 }.Select(MerchantRules.Badge));
    }

    private static MerchantCandidate C(string name, int level, double distance, double rating, string gender = "female") => new()
    {
        Id = Guid.NewGuid(),
        Name = name,
        Gender = gender,
        Level = level,
        Rating = rating,
        RatingCount = 0,
        CompletedJobs = 0,
        DistanceM = distance,
        WorkingRadiusM = 5000,
    };

    [Fact]
    public void Ranks_level_2_first_then_distance_or_rating()
    {
        var list = new[] { C("near", 1, 100, 4), C("far", 1, 900, 4.9), C("pro", 2, 5000, 3.9) };
        Assert.Equal(["pro", "near", "far"], MerchantRules.Rank(list, false).Select(c => c.Name));
        Assert.Equal(["pro", "far", "near"], MerchantRules.Rank(list, true).Select(c => c.Name));
        Assert.Equal("near", MerchantRules.Rank([C("far", 1, 900, 4), C("near", 1, 100, 4)], true)[0].Name);
    }

    [Fact]
    public void Keeps_the_working_radius_and_women_only()
    {
        var man = C("man", 1, 0, 4, "male");
        var woman = C("woman", 1, 0, 4);
        var far = C("far", 1, 0, 4);
        var d = new Dictionary<Guid, double> { [man.Id] = 300, [woman.Id] = 900, [far.Id] = 6000 };
        Assert.Equal(["man", "woman"], MerchantRules.Eligible([man, woman, far], d, false).Select(c => c.Name));
        Assert.Equal(["woman"], MerchantRules.Eligible([man, woman, far], d, true).Select(c => c.Name));
    }

    [Fact]
    public void Spreads_perf_merchants_on_a_spiral()
    {
        Assert.Equal(PerfSeedCommand.Centre, PerfSeedCommand.SpiralPoint(0, 10));
        Assert.NotEqual(PerfSeedCommand.Centre, PerfSeedCommand.SpiralPoint(5, 10));
    }
}
