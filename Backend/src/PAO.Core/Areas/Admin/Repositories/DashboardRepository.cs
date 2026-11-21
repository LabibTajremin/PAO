using System.Globalization;
using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Admin;
using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Repositories;

/// <summary>
/// The dashboard read model (`admin.stats_providers`, `admin.stats_bookings_daily`, A-09).
/// Writes take the subscriber's own context, so they commit with its processed-event row.
/// </summary>
public sealed class DashboardRepository(PaoDbContext db)
{
    /// <summary>Provider counts by status and level, open complaints and booking days since `since`.</summary>
    public async Task<DashboardCounts> Counts(DateOnly since, CancellationToken cancellationToken)
    {
        // An active provider without Level 1 is still pending verification (PRD §6.4).
        var providers = await db.Set<StatsProviderRecord>().AsNoTracking().ToListAsync(cancellationToken);
        var byStatus = providers.GroupBy(p => p.Status == "active" && p.Level == 0 ? "pending" : p.Status).ToDictionary(g => g.Key, g => g.Count());
        var byLevel = providers.GroupBy(p => p.Level.ToString(CultureInfo.InvariantCulture)).ToDictionary(g => g.Key, g => g.Count());
        var open = await db.Set<ComplaintRecord>().CountAsync(c => c.Status != "resolved", cancellationToken);
        var days = await db.Set<BookingDayRecord>().AsNoTracking().Where(d => d.Day >= since).OrderBy(d => d.Day).ToListAsync(cancellationToken);
        return new DashboardCounts(byStatus, byLevel, open,
            [.. days.Select(d => new DayCount(d.Day.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), d.Requested, d.Completed))]);
    }

    /// <summary>Counts a new provider account as active at level 0.</summary>
    public static Task AddProvider(PaoDbContext db, Guid id, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync(
        $"INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ({id}, 'active', 0) ON CONFLICT DO NOTHING", cancellationToken);

    /// <summary>Records a provider's level.</summary>
    public static Task SetLevel(PaoDbContext db, Guid id, int level, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ({id}, 'active', {level})
        ON CONFLICT (provider_id) DO UPDATE SET level = EXCLUDED.level
        """, cancellationToken);

    /// <summary>Records a provider's account status.</summary>
    public static Task SetStatus(PaoDbContext db, Guid id, string status, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO admin.stats_providers (provider_id, status, level) VALUES ({id}, {status}, 0)
        ON CONFLICT (provider_id) DO UPDATE SET status = EXCLUDED.status
        """, cancellationToken);

    /// <summary>Forgets a deleted provider.</summary>
    public static Task DeleteProvider(PaoDbContext db, Guid id, CancellationToken cancellationToken) =>
        db.Database.ExecuteSqlAsync($"DELETE FROM admin.stats_providers WHERE provider_id = {id}", cancellationToken);

    /// <summary>Adds requests and completions to a Dhaka day.</summary>
    public static Task BumpBookings(PaoDbContext db, DateOnly day, int requested, int completed, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO admin.stats_bookings_daily (day, requested, completed) VALUES ({day}, {requested}, {completed})
        ON CONFLICT (day) DO UPDATE SET requested = admin.stats_bookings_daily.requested + EXCLUDED.requested,
            completed = admin.stats_bookings_daily.completed + EXCLUDED.completed
        """, cancellationToken);
}
