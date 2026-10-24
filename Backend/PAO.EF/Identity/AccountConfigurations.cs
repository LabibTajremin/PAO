using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Identity;

/// <summary>Maps <see cref="Account"/> to `identity.accounts`.</summary>
public sealed class AccountConfiguration : IEntityTypeConfiguration<Account>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Account> builder)
    {
        builder.ToTable("accounts", Schemas.Identity);
        builder.HasKey(a => a.Id);
    }
}

/// <summary>Maps <see cref="AccountRole"/> to `identity.account_roles`.</summary>
public sealed class AccountRoleConfiguration : IEntityTypeConfiguration<AccountRole>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<AccountRole> builder)
    {
        builder.ToTable("account_roles", Schemas.Identity);
        builder.HasKey(r => new { r.AccountId, r.Role });
    }
}

/// <summary>Maps <see cref="AdminCredentials"/> to `identity.admin_credentials`.</summary>
public sealed class AdminCredentialsConfiguration : IEntityTypeConfiguration<AdminCredentials>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<AdminCredentials> builder)
    {
        builder.ToTable("admin_credentials", Schemas.Identity);
        builder.HasKey(c => c.AccountId);
    }
}

/// <summary>Maps <see cref="BlockedPhone"/> to `identity.blocked_phones`.</summary>
public sealed class BlockedPhoneConfiguration : IEntityTypeConfiguration<BlockedPhone>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BlockedPhone> builder)
    {
        builder.ToTable("blocked_phones", Schemas.Identity);
        builder.HasKey(b => b.Phone);
    }
}
