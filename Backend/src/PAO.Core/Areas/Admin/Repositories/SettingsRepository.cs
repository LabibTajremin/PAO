using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Admin;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Admin.Repositories;

/// <summary>The settings table of the admin schema (A-10).</summary>
public sealed class SettingsRepository(PaoDbContext db, OutboxWriter outbox)
{
    /// <summary>Every setting by key.</summary>
    public Task<List<SettingRecord>> List(CancellationToken cancellationToken) =>
        db.Set<SettingRecord>().AsNoTracking().OrderBy(s => s.Key).ToListAsync(cancellationToken);

    /// <summary>The setting; `admin.setting_not_found` without one.</summary>
    public async Task<SettingRecord> Get(string key, CancellationToken cancellationToken) =>
        await db.Set<SettingRecord>().AsNoTracking().FirstOrDefaultAsync(s => s.Key == key, cancellationToken)
            ?? throw new DomainException(AdminReasons.SettingNotFound);

    /// <summary>Saves the value with its `SettingChanged` event in the command's transaction.</summary>
    public async Task Update(SettingRecord s, SettingChanged domainEvent, CancellationToken cancellationToken)
    {
        await db.Set<SettingRecord>().Where(r => r.Key == s.Key).ExecuteUpdateAsync(
            u => u.SetProperty(r => r.Value, s.Value).SetProperty(r => r.UpdatedAt, s.UpdatedAt).SetProperty(r => r.UpdatedBy, s.UpdatedBy), cancellationToken);
        await outbox.Write(db, Schemas.Admin, s.Key, domainEvent, cancellationToken);
    }
}
