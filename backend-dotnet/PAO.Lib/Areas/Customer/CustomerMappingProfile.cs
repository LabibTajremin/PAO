using PAO.EF.Customer;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Customer;

/// <summary>The Customer area's maps: rows to profiles and addresses, those to views and contract DTOs.</summary>
public sealed class CustomerMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<CustomerProfileRecord, CustomerProfile>((r, _) => new CustomerProfile
        {
            Id = r.Id,
            Name = r.Name,
            PhotoMediaId = r.PhotoMediaId,
            Language = r.Language,
        })
        .Add<AddressRecord, SavedAddress>((r, _) => new SavedAddress
        {
            Id = r.Id,
            CustomerId = r.CustomerId,
            Label = r.Label,
            Line1 = r.Line1,
            Line2 = r.Line2,
            Area = r.Area,
            Location = new GeoPoint { Lat = r.Location.Y, Lng = r.Location.X },
            IsDefault = r.IsDefault,
            CreatedAt = r.CreatedAt,
        })
        .Add<SavedAddress, AddressView>((a, _) => new AddressView
        {
            Id = a.Id,
            Label = a.Label,
            Line1 = a.Line1,
            Line2 = a.Line2,
            Area = a.Area,
            Location = a.Location,
            IsDefault = a.IsDefault,
        })
        .Add<SavedAddress, CustomerAddress>((a, _) => new CustomerAddress
        {
            Id = a.Id,
            CustomerId = a.CustomerId,
            Label = a.Label,
            Line1 = a.Line1,
            Line2 = a.Line2,
            Area = a.Area,
            Location = a.Location,
        })
        .Add<CustomerProfileDetails, CustomerProfileView>((d, _) => new CustomerProfileView
        {
            Id = d.Profile.Id,
            Name = d.Profile.Name,
            Phone = d.Phone,
            PhotoUrl = d.PhotoUrl,
            Language = d.Profile.Language,
        })
        .Add<CustomerProfileRecord, CustomerRecord>((r, _) => new CustomerRecord
        {
            Id = r.Id,
            Name = r.Name,
            Phone = r.Phone,
            Status = r.AccountStatus,
            Bookings = r.Bookings,
            CreatedAt = r.CreatedAt,
        });
}
