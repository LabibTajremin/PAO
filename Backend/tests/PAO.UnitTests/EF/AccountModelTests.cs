using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Identity;

namespace PAO.UnitTests.EF;

public sealed class AccountModelTests
{
    [Fact]
    public void The_model_maps_the_identity_and_audit_tables_with_their_columns()
    {
        using var db = new DesignTimeDbContextFactory().CreateDbContext([]);
        var roles = db.Model.FindEntityType(typeof(AccountRole))!;
        Assert.Equal(("account_roles", Schemas.Identity), (roles.GetTableName(), roles.GetSchema()));
        Assert.Equal(["account_id", "granted_at", "role"], roles.GetProperties().Select(p => p.GetColumnName()).Order());
        var blocked = db.Model.FindEntityType(typeof(BlockedPhone))!;
        Assert.Equal(["blocked_at", "phone", "reason"], blocked.GetProperties().Select(p => p.GetColumnName()).Order());
        var entries = db.Model.FindEntityType(typeof(PAO.EF.Audit.Entry))!;
        Assert.Equal(("entries", "jsonb"), (entries.GetTableName(), entries.FindProperty("Before")!.GetColumnType()));
        var row = new BlockedPhone { Phone = "p", Reason = "r", BlockedAt = DateTimeOffset.UnixEpoch };
        var grant = new AccountRole { AccountId = Guid.Empty, Role = "customer", GrantedAt = DateTimeOffset.UnixEpoch };
        Assert.Equal(("r", DateTimeOffset.UnixEpoch, DateTimeOffset.UnixEpoch), (row.Reason, row.BlockedAt, grant.GrantedAt));
    }
}
