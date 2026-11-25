using System.Text.Json;
using PAO.EF.Booking;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Booking.Repositories;

/// <summary>Converts subscription rows to the stored model and back.</summary>
public static class SubscriptionRows
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>Lines as the jsonb columns store them.</summary>
    public static string LinesJson(IReadOnlyList<BookingLine> lines) => JsonSerializer.Serialize(lines, Json);

    /// <summary>Lines from a jsonb column.</summary>
    public static IReadOnlyList<BookingLine> Lines(string json) => JsonSerializer.Deserialize<List<BookingLine>>(json, Json)!;

    /// <summary>The stored model of a row, without its dates.</summary>
    public static StoredSubscription ToModel(SubscriptionRecord r) => new()
    {
        Id = r.Id,
        Number = r.Number,
        Customer = new BookingParty(r.CustomerId, r.CustomerName, r.CustomerPhone),
        Provider = new BookingParty(r.ProviderId, r.ProviderName, r.ProviderPhone),
        ServiceId = r.ServiceId,
        ServiceName = new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn },
        Address = new AddressSnapshot(r.AddressId, r.AddressArea, r.AddressLine1, r.AddressLine2, new GeoPoint { Lat = r.AddressLat, Lng = r.AddressLng }),
        Note = r.Note,
        Lines = Lines(r.Items),
        TotalPaisa = r.TotalPaisa,
        Unit = r.Unit,
        Plan = new DeliveryPlan
        {
            Pattern = r.Pattern,
            Weekdays = r.Weekdays,
            DayOfMonth = r.DayOfMonth,
            StartDate = r.StartDate,
            EndDate = r.EndDate,
            Count = r.Count,
        },
        Window = new DeliveryWindow { Start = Clock(r.WindowStart), End = Clock(r.WindowEnd) },
        Cutoff = r.Cutoff,
        Status = r.Status,
        DeclineReason = r.DeclineReason,
        IdempotencyKey = r.IdempotencyKey,
        CreatedAt = r.CreatedAt,
        AcceptedAt = r.AcceptedAt,
    };

    /// <summary>A new row for a subscription.</summary>
    public static SubscriptionRecord ToRecord(StoredSubscription s) => new()
    {
        Id = s.Id,
        CustomerId = s.Customer.Id,
        ProviderId = s.Provider.Id,
        ServiceId = s.ServiceId,
        ServiceNameEn = s.ServiceName.En,
        ServiceNameBn = s.ServiceName.Bn,
        CustomerName = s.Customer.Name,
        CustomerPhone = s.Customer.Phone,
        ProviderName = s.Provider.Name,
        ProviderPhone = s.Provider.Phone,
        AddressId = s.Address.Id,
        AddressArea = s.Address.Area,
        AddressLine1 = s.Address.Line1,
        AddressLine2 = s.Address.Line2,
        AddressLat = s.Address.Location.Lat,
        AddressLng = s.Address.Location.Lng,
        Note = s.Note,
        Items = LinesJson(s.Lines),
        TotalPaisa = s.TotalPaisa,
        Unit = s.Unit,
        Pattern = s.Plan.Pattern,
        Weekdays = [.. s.Plan.Weekdays],
        DayOfMonth = s.Plan.DayOfMonth,
        WindowStart = s.Window.From,
        WindowEnd = s.Window.To,
        Cutoff = s.Cutoff,
        StartDate = s.Plan.StartDate,
        EndDate = s.Plan.EndDate,
        Count = s.Plan.Count,
        Status = s.Status,
        DeclineReason = s.DeclineReason,
        IdempotencyKey = s.IdempotencyKey,
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.CreatedAt,
    };

    private static string Clock(TimeOnly time) => time.ToString("HH:mm", System.Globalization.CultureInfo.InvariantCulture);
}
