using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Notification;

/// <summary>A row of `notification.notifications`: one inbox entry.</summary>
public sealed class NotificationRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The recipient account.</summary>
    public Guid RecipientId { get; set; }
    /// <summary>`customer` or `partner`.</summary>
    public required string App { get; set; }
    /// <summary>The template that produced it.</summary>
    public required string Type { get; set; }
    /// <summary>The rendered title.</summary>
    public required string Title { get; set; }
    /// <summary>The rendered body.</summary>
    public required string Body { get; set; }
    /// <summary>The booking it is about, if any.</summary>
    public Guid? BookingId { get; set; }
    /// <summary>Unique per recipient; makes redelivered events notify once.</summary>
    public required string DedupeKey { get; set; }
    /// <summary>When it was read.</summary>
    public DateTimeOffset? ReadAt { get; set; }
    /// <summary>When it was stored.</summary>
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>A row of `notification.device_tokens`.</summary>
public sealed class DeviceTokenRecord
{
    /// <summary>The push token.</summary>
    public required string Token { get; set; }
    /// <summary>The account that registered it last.</summary>
    public Guid AccountId { get; set; }
    /// <summary>`customer` or `partner`.</summary>
    public required string App { get; set; }
    /// <summary>`android`, `ios` or `web`.</summary>
    public required string Platform { get; set; }
    /// <summary>When it was registered last.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>Maps <see cref="NotificationRecord"/> to `notification.notifications`.</summary>
public sealed class NotificationConfiguration : IEntityTypeConfiguration<NotificationRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<NotificationRecord> builder)
    {
        builder.ToTable("notifications", Schemas.Notification);
        builder.HasKey(n => n.Id);
    }
}

/// <summary>Maps <see cref="DeviceTokenRecord"/> to `notification.device_tokens`.</summary>
public sealed class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceTokenRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<DeviceTokenRecord> builder)
    {
        builder.ToTable("device_tokens", Schemas.Notification);
        builder.HasKey(d => d.Token);
    }
}
