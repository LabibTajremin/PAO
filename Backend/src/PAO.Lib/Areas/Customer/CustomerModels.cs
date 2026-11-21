using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Customer;

/// <summary>The `CustomerProfileUpdate` body (C-01).</summary>
public sealed record CustomerProfileInput
{
    /// <summary>The display name.</summary>
    public string Name { get; init; } = string.Empty;
    /// <summary>`en` or `bn`.</summary>
    public string Language { get; init; } = string.Empty;
    /// <summary>A confirmed avatar upload of the customer.</summary>
    public Guid? PhotoMediaId { get; init; }
}

/// <summary>The `CustomerProfile` the app shows.</summary>
public sealed record CustomerProfileView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The account phone.</summary>
    public required string Phone { get; init; }
    /// <summary>A short-lived photo URL; absent without a photo.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PhotoUrl { get; init; }
    /// <summary>The language.</summary>
    public required string Language { get; init; }
}

/// <summary>A profile with what only identity and media know: the phone and the photo URL.</summary>
public sealed record CustomerProfileDetails(CustomerProfile Profile, string Phone, string? PhotoUrl);

/// <summary>The `AddressInput` body (C-02); missing lines are empty.</summary>
public sealed record AddressInput
{
    /// <summary>`home`, `office` or `other`.</summary>
    public string Label { get; init; } = string.Empty;
    /// <summary>The first line.</summary>
    public string Line1 { get; init; } = string.Empty;
    /// <summary>The second line.</summary>
    public string? Line2 { get; init; }
    /// <summary>The neighbourhood.</summary>
    public string? Area { get; init; }
    /// <summary>The pin.</summary>
    public GeoPoint Location { get; init; } = new() { Lat = 0, Lng = 0 };
    /// <summary>Whether to make it the default.</summary>
    public bool? IsDefault { get; init; }
}

/// <summary>A saved address with its default flag, as the Customer area keeps it.</summary>
public sealed record SavedAddress
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The customer.</summary>
    public required Guid CustomerId { get; init; }
    /// <summary>The label.</summary>
    public required string Label { get; init; }
    /// <summary>The first line.</summary>
    public required string Line1 { get; init; }
    /// <summary>The second line.</summary>
    public required string Line2 { get; init; }
    /// <summary>The neighbourhood.</summary>
    public required string Area { get; init; }
    /// <summary>The pin.</summary>
    public required GeoPoint Location { get; init; }
    /// <summary>Whether it is the default.</summary>
    public required bool IsDefault { get; init; }
    /// <summary>When it was saved.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>The `Address` the app shows.</summary>
public sealed record AddressView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The label.</summary>
    public required string Label { get; init; }
    /// <summary>The first line.</summary>
    public required string Line1 { get; init; }
    /// <summary>The second line.</summary>
    public required string Line2 { get; init; }
    /// <summary>The neighbourhood.</summary>
    public required string Area { get; init; }
    /// <summary>The pin.</summary>
    public required GeoPoint Location { get; init; }
    /// <summary>Whether it is the default.</summary>
    public required bool IsDefault { get; init; }
}

/// <summary>The `AddressList`, default first.</summary>
public sealed record AddressListView
{
    /// <summary>The addresses.</summary>
    public required IReadOnlyList<AddressView> Items { get; init; }
}

/// <summary>The `ServiceAreaCheck` (C35).</summary>
public sealed record ServiceAreaCheckView
{
    /// <summary>Whether the point is inside the launch area.</summary>
    public required bool Covered { get; init; }
}

/// <summary>Why the Customer area refused something; only the error map turns them into API errors.</summary>
public static class CustomerReasons
{
    /// <summary>Name, language or address fields break the rules.</summary>
    public const string Invalid = "customer.invalid";
    /// <summary>The photo is not a confirmed avatar upload of this customer.</summary>
    public const string InvalidPhoto = "customer.invalid_photo";
    /// <summary>The pin lies outside Bangladesh.</summary>
    public const string OutsideCountry = "customer.outside_country";
    /// <summary>The customer already has the maximum number of addresses.</summary>
    public const string AddressLimit = "customer.address_limit";
    /// <summary>Addresses need a profile first.</summary>
    public const string ProfileRequired = "customer.profile_required";
}
