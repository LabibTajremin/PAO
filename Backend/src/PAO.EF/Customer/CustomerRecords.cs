using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NetTopologySuite.Geometries;

namespace PAO.EF.Customer;

/// <summary>A row of `customer.customers`: the profile plus the identity copies the admin list shows.</summary>
public sealed class CustomerProfileRecord
{
    /// <summary>The account id.</summary>
    public Guid Id { get; set; }
    /// <summary>The display name.</summary>
    public required string Name { get; set; }
    /// <summary>The confirmed avatar upload, if any.</summary>
    public Guid? PhotoMediaId { get; set; }
    /// <summary>`en` or `bn`.</summary>
    public required string Language { get; set; }
    /// <summary>When the profile was first saved.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When the profile last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>The account phone, copied for the admin list.</summary>
    public required string Phone { get; set; }
    /// <summary>The account status, kept current from identity events.</summary>
    public required string AccountStatus { get; set; }
    /// <summary>How many bookings the customer requested.</summary>
    public int Bookings { get; set; }
}

/// <summary>A row of `customer.addresses`: a saved place with its map pin.</summary>
public sealed class AddressRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The owning customer.</summary>
    public Guid CustomerId { get; set; }
    /// <summary>`home`, `office` or `other`.</summary>
    public required string Label { get; set; }
    /// <summary>The first line.</summary>
    public required string Line1 { get; set; }
    /// <summary>The second line.</summary>
    public required string Line2 { get; set; }
    /// <summary>The neighbourhood.</summary>
    public required string Area { get; set; }
    /// <summary>The pin; X is the longitude, Y the latitude (SRID 4326).</summary>
    public required Point Location { get; set; }
    /// <summary>Whether it is the customer's default address.</summary>
    public bool IsDefault { get; set; }
    /// <summary>When it was saved.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>Maps <see cref="CustomerProfileRecord"/> to `customer.customers`.</summary>
public sealed class CustomerConfiguration : IEntityTypeConfiguration<CustomerProfileRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<CustomerProfileRecord> builder)
    {
        builder.ToTable("customers", Schemas.Customer);
        builder.HasKey(c => c.Id);
    }
}

/// <summary>Maps <see cref="AddressRecord"/> to `customer.addresses`.</summary>
public sealed class AddressConfiguration : IEntityTypeConfiguration<AddressRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<AddressRecord> builder)
    {
        builder.ToTable("addresses", Schemas.Customer);
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Location).HasColumnType("geography (point, 4326)");
    }
}
