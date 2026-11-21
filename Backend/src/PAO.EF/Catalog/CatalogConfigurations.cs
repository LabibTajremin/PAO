using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Catalog;

/// <summary>Maps <see cref="CategoryRecord"/> to `catalog.categories`.</summary>
public sealed class CategoryConfiguration : IEntityTypeConfiguration<CategoryRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<CategoryRecord> builder)
    {
        builder.ToTable("categories", Schemas.Catalog);
        builder.HasKey(c => c.Id);
    }
}

/// <summary>Maps <see cref="ServiceRecord"/> to `catalog.services`.</summary>
public sealed class ServiceConfiguration : IEntityTypeConfiguration<ServiceRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ServiceRecord> builder)
    {
        builder.ToTable("services", Schemas.Catalog);
        builder.HasKey(s => s.Id);
        builder.Property(s => s.RequiresLevel2).HasColumnName("requires_level_2");
        builder.Property(s => s.Level2Checklist).HasColumnType("jsonb");
    }
}

/// <summary>Maps <see cref="SubServiceRecord"/> to `catalog.sub_services`.</summary>
public sealed class SubServiceConfiguration : IEntityTypeConfiguration<SubServiceRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<SubServiceRecord> builder)
    {
        builder.ToTable("sub_services", Schemas.Catalog);
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Description).HasColumnType("jsonb");
        builder.Property(s => s.Inclusions).HasColumnType("jsonb");
        builder.Property(s => s.Exclusions).HasColumnType("jsonb");
    }
}

/// <summary>Maps <see cref="PriceVersionRecord"/> to `catalog.price_versions`.</summary>
public sealed class PriceVersionConfiguration : IEntityTypeConfiguration<PriceVersionRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<PriceVersionRecord> builder)
    {
        builder.ToTable("price_versions", Schemas.Catalog);
        builder.HasKey(p => p.Id);
    }
}

/// <summary>Maps <see cref="CatalogVersionRecord"/> to `catalog.catalog_version`.</summary>
public sealed class CatalogVersionConfiguration : IEntityTypeConfiguration<CatalogVersionRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<CatalogVersionRecord> builder)
    {
        builder.ToTable("catalog_version", Schemas.Catalog);
        builder.HasKey(v => v.Singleton);
    }
}
