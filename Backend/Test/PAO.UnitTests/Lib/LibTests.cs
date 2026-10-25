using System.Reflection;
using System.Text.Json;
using FluentValidation;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;
using PAO.Lib.Validation;

namespace PAO.UnitTests.Lib;

public sealed class MapperTests
{
    private sealed record Row(int Id, string Name);

    private sealed record View(string Label);

    private sealed record Page(IReadOnlyList<View> Items);

    private sealed class RowProfile : IMappingProfile
    {
        public void Configure(MappingRegistry registry) => registry
            .Add<Row, View>((row, _) => new View($"{row.Id}:{row.Name}"))
            .Add<Row[], Page>((rows, mapper) => new Page(mapper.MapAll<Row, View>(rows)));
    }

    [Fact]
    public void Maps_with_the_registered_profile_and_nests_through_the_mapper()
    {
        var mapper = new Mapper([new RowProfile()]);
        Assert.Equal(new View("1:a"), mapper.Map<Row, View>(new Row(1, "a")));
        var page = mapper.Map<Row[], Page>([new Row(1, "a"), new Row(2, "b")]);
        Assert.Equal(["1:a", "2:b"], page.Items.Select(v => v.Label));
    }

    [Fact]
    public void Fails_loudly_for_a_missing_map_and_a_duplicate_one()
    {
        var mapper = new Mapper([]);
        var missing = Assert.Throws<InvalidOperationException>(() => mapper.Map<Row, View>(new Row(1, "a")));
        Assert.Contains("no map from Row to View", missing.Message, StringComparison.Ordinal);
        Assert.Throws<InvalidOperationException>(() => mapper.MapAll<Row, View>([]));
        var duplicate = Assert.Throws<InvalidOperationException>(() => new Mapper([new RowProfile(), new RowProfile()]));
        Assert.Contains("already registered", duplicate.Message, StringComparison.Ordinal);
    }
}

public sealed class DomainExceptionTests
{
    [Fact]
    public void Carries_its_reason_and_cause()
    {
        var cause = new InvalidOperationException("db");
        var error = new DomainException(BookingReason, cause);
        Assert.Equal(BookingReason, error.Reason);
        Assert.Same(cause, error.InnerException);
        Assert.True(DomainException.Is(error, BookingReason));
        Assert.False(DomainException.Is(error, "other"));
        Assert.False(DomainException.Is(cause, BookingReason));
        Assert.False(DomainException.Is(null, BookingReason));
    }

    private const string BookingReason = "booking.not_found";
}

public sealed class ValidationTests
{
    private sealed record Signup(string AccountId, string Phone, long AmountPaisa);

    private sealed class SignupValidator : AbstractValidator<Signup>
    {
        public SignupValidator()
        {
            RuleFor(s => s.AccountId).Uuid();
            RuleFor(s => s.Phone).NotEmpty().BangladeshPhone();
            RuleFor(s => s.AmountPaisa).Paisa();
        }
    }

    [Fact]
    public void Reports_camel_case_paths_and_the_first_failure_per_property()
    {
        ValidationSetup.Configure();
        var validator = new SignupValidator();
        Assert.True(validator.Validate(new Signup(Guid.NewGuid().ToString(), "01712345678", 0)).IsValid);
        var result = validator.Validate(new Signup("nope", string.Empty, -1));
        Assert.Equal(["accountId", "phone", "amountPaisa"], result.Errors.Select(e => e.PropertyName));
        Assert.Equal("accountId must be a UUID", result.Errors[0].ErrorMessage);
        Assert.Equal("phone must be a Bangladeshi mobile number", validator.Validate(new Signup(Guid.NewGuid().ToString(), "123", 1)).Errors[0].ErrorMessage);
        Assert.False(validator.Validate(new Signup(null!, "01712345678", 1)).IsValid);
    }
}

public sealed class ContractTests
{
    [Fact]
    public void Seed_ids_match_the_uuid_v5_derivation()
    {
        Assert.Equal(Guid.Parse("36dab175-76f7-5578-9d1a-bfec11c6c195"), SeedIds.For("service", "electrician"));
    }

    [Theory]
    [InlineData("01712345678", "+8801712345678")]
    [InlineData("+880 1712-345678", "+8801712345678")]
    [InlineData("8801712345678", "+8801712345678")]
    [InlineData("(017) 12345678", "+8801712345678")]
    [InlineData("01212345678", null)]
    [InlineData("abc", null)]
    public void Normalizes_bangladeshi_mobile_numbers(string raw, string? expected)
    {
        Assert.Equal(expected, PhoneNumber.Normalize(raw));
    }

    [Fact]
    public void Masks_all_but_the_last_three_digits()
    {
        Assert.Equal("***********678", PhoneNumber.Mask("+8801712345678"));
        Assert.Equal("***", PhoneNumber.Mask("12"));
    }

    [Fact]
    public void Admin_roles_are_the_console_roles()
    {
        Assert.Equal(4, Roles.Admin.Count);
        Assert.DoesNotContain(Roles.Customer, Roles.Admin);
        Assert.Same(Unit.Value, Unit.Value);
    }

    public static TheoryData<Type> EventTypes() => [.. typeof(IDomainEvent).Assembly.GetTypes()
        .Where(t => typeof(IDomainEvent).IsAssignableFrom(t) && t is { IsClass: true, IsAbstract: false })];

    [Theory]
    [MemberData(nameof(EventTypes))]
    public void Events_carry_a_stable_area_scoped_name_in_their_camel_case_payload(Type type)
    {
        var domainEvent = (IDomainEvent)Activator.CreateInstance(type)!;
        var area = type.Namespace!.Split('.')[^1];
        var prefix = area == "Merchant" ? "provider" : area.ToLowerInvariant();
        Assert.Equal($"{prefix}.{type.Name}", domainEvent.Name);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(domainEvent, type, JsonSerializerOptions.Web));
        Assert.Equal(domainEvent.Name, json.RootElement.GetProperty("name").GetString());
        Assert.All(json.RootElement.EnumerateObject(), p => Assert.True(char.IsLower(p.Name[0])));
    }

    [Fact]
    public void Every_area_has_contract_types_in_the_lib()
    {
        var areas = typeof(IDomainEvent).Assembly.GetTypes()
            .Select(t => t.Namespace)
            .Where(n => n?.StartsWith("PAO.Lib.Areas.", StringComparison.Ordinal) == true)
            .Select(n => n!.Split('.')[3])
            .ToHashSet();
        Assert.Equal(12, areas.Count);
        Assert.Contains("Billing", areas);
        Assert.NotNull(typeof(SeedIds).GetMethod(nameof(SeedIds.UuidV5), BindingFlags.Public | BindingFlags.Static));
    }
}
