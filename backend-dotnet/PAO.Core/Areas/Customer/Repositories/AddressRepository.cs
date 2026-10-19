using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using PAO.EF;
using PAO.EF.Customer;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Customer.Repositories;

/// <summary>
/// Saved addresses (`customer.addresses`) on PostGIS. Writes run in the command's
/// transaction holding the customer's row lock, so the limit and default checks race no one.
/// </summary>
public sealed class AddressRepository(PaoDbContext db, IMapper mapper)
{
    /// <summary>Inserts `a`, making it the default when asked or when it is the first; `customer.address_limit` past `limit`.</summary>
    public async Task<SavedAddress> Add(SavedAddress a, int limit, CancellationToken cancellationToken)
    {
        await Lock(a.CustomerId, cancellationToken);
        var count = await Rows(a.CustomerId).CountAsync(cancellationToken);
        if (count >= limit)
        {
            throw new DomainException(CustomerReasons.AddressLimit);
        }
        var saved = a with { IsDefault = a.IsDefault || count == 0 };
        if (saved.IsDefault)
        {
            await ClearDefault(a.CustomerId, cancellationToken);
        }
        db.Set<AddressRecord>().Add(new AddressRecord
        {
            Id = saved.Id,
            CustomerId = saved.CustomerId,
            Label = saved.Label,
            Line1 = saved.Line1,
            Line2 = saved.Line2,
            Area = saved.Area,
            Location = Pin(saved.Location),
            IsDefault = saved.IsDefault,
            CreatedAt = saved.CreatedAt,
            UpdatedAt = saved.CreatedAt,
        });
        await db.SaveChangesAsync(cancellationToken);
        return saved;
    }

    /// <summary>Edits `a`; a true `IsDefault` makes it the default, false leaves the default alone.</summary>
    public async Task Update(SavedAddress a, DateTimeOffset at, CancellationToken cancellationToken)
    {
        await Lock(a.CustomerId, cancellationToken);
        var pin = Pin(a.Location);
        var changed = await One(a.CustomerId, a.Id).ExecuteUpdateAsync(
            u => u.SetProperty(r => r.Label, a.Label).SetProperty(r => r.Line1, a.Line1).SetProperty(r => r.Line2, a.Line2)
                .SetProperty(r => r.Area, a.Area).SetProperty(r => r.Location, pin).SetProperty(r => r.UpdatedAt, at),
            cancellationToken);
        if (changed == 0)
        {
            throw new DomainException(CustomerErrors.AddressNotFound);
        }
        if (a.IsDefault)
        {
            await MarkDefault(a.CustomerId, a.Id, cancellationToken);
        }
    }

    /// <summary>Makes the address the default.</summary>
    public async Task SetDefault(Guid customerId, Guid addressId, CancellationToken cancellationToken)
    {
        await Lock(customerId, cancellationToken);
        await MarkDefault(customerId, addressId, cancellationToken);
    }

    /// <summary>Removes an address; deleting the default promotes the newest one left.</summary>
    public async Task Delete(Guid customerId, Guid addressId, CancellationToken cancellationToken)
    {
        await Lock(customerId, cancellationToken);
        var wasDefault = await db.Database.SqlQuery<bool>($"""
            DELETE FROM customer.addresses WHERE id = {addressId} AND customer_id = {customerId} RETURNING is_default AS "Value"
            """).ToListAsync(cancellationToken);
        if (wasDefault.Count == 0)
        {
            throw new DomainException(CustomerErrors.AddressNotFound);
        }
        if (wasDefault[0])
        {
            await db.Database.ExecuteSqlAsync($"""
                UPDATE customer.addresses SET is_default = true
                WHERE id = (SELECT a.id FROM customer.addresses a WHERE a.customer_id = {customerId}
                    ORDER BY a.created_at DESC, a.id DESC LIMIT 1)
                """, cancellationToken);
        }
    }

    /// <summary>The customer's addresses, default first, then newest.</summary>
    public async Task<IReadOnlyList<SavedAddress>> List(Guid customerId, CancellationToken cancellationToken)
    {
        var rows = await Rows(customerId).OrderByDescending(a => a.IsDefault).ThenByDescending(a => a.CreatedAt)
            .ThenByDescending(a => a.Id).ToListAsync(cancellationToken);
        return mapper.MapAll<AddressRecord, SavedAddress>(rows);
    }

    /// <summary>One of the customer's addresses; `customer.address_not_found` otherwise.</summary>
    public async Task<SavedAddress> Get(Guid customerId, Guid addressId, CancellationToken cancellationToken)
    {
        var row = await One(customerId, addressId).FirstOrDefaultAsync(cancellationToken)
            ?? throw new DomainException(CustomerErrors.AddressNotFound);
        return mapper.Map<AddressRecord, SavedAddress>(row);
    }

    private static Point Pin(GeoPoint p) => new(p.Lng, p.Lat) { SRID = 4326 };

    private IQueryable<AddressRecord> Rows(Guid customerId) => db.Set<AddressRecord>().Where(a => a.CustomerId == customerId);

    private IQueryable<AddressRecord> One(Guid customerId, Guid id) => Rows(customerId).Where(a => a.Id == id);

    private Task<int> ClearDefault(Guid customerId, CancellationToken cancellationToken) =>
        Rows(customerId).Where(a => a.IsDefault).ExecuteUpdateAsync(u => u.SetProperty(a => a.IsDefault, false), cancellationToken);

    private async Task MarkDefault(Guid customerId, Guid addressId, CancellationToken cancellationToken)
    {
        await ClearDefault(customerId, cancellationToken);
        if (await One(customerId, addressId).ExecuteUpdateAsync(u => u.SetProperty(a => a.IsDefault, true), cancellationToken) == 0)
        {
            throw new DomainException(CustomerErrors.AddressNotFound);
        }
    }

    /// <summary>Holds the customer's row until the transaction ends; `customer.profile_required` without a profile.</summary>
    private async Task Lock(Guid customerId, CancellationToken cancellationToken)
    {
        var locked = await db.Database.SqlQuery<Guid>($"""
            SELECT id AS "Value" FROM customer.customers WHERE id = {customerId} FOR UPDATE
            """).ToListAsync(cancellationToken);
        if (locked.Count == 0)
        {
            throw new DomainException(CustomerReasons.ProfileRequired);
        }
    }
}
