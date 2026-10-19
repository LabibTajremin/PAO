using PAO.EF.Admin;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Admin;

/// <summary>A merchant row with the names of its services.</summary>
public sealed record MerchantWithServices(MerchantRecord Record, IReadOnlyList<ServiceRefView> Services);

/// <summary>The Admin area's maps.</summary>
public sealed class AdminMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => Customers(People(Complaints(registry)));

    private static MappingRegistry Complaints(MappingRegistry registry) => registry
        .Add<SettingRecord, SettingView>((s, _) => new SettingView
        {
            Key = s.Key,
            Value = s.Value,
            Type = s.Type,
            Description = s.Description,
            UpdatedAt = IsoTime.Format(s.UpdatedAt),
            UpdatedBy = s.UpdatedBy,
        })
        .Add<Complaint, ComplaintView>((c, _) => new ComplaintView
        {
            Id = c.Row.Id,
            TicketNumber = c.TicketNumber,
            BookingId = c.Row.BookingId,
            ReporterRole = c.Row.ReporterRole,
            ReporterId = c.Row.ReporterId,
            AgainstId = c.Row.AgainstId,
            Reason = c.Row.Reason,
            Description = c.Row.Description,
            PhotoMediaIds = c.Row.PhotoMediaIds,
            Status = c.Row.Status,
            AssigneeId = c.Row.AssigneeId,
            Resolution = c.Row.Resolution,
            Verified = c.Row.Verified,
            Comments = [.. c.Comments.Select(m => new ComplaintCommentView { AuthorId = m.AuthorId, Body = m.Body, At = IsoTime.Format(m.At) })],
            CreatedAt = IsoTime.Format(c.Row.CreatedAt),
            ResolvedAt = c.Row.ResolvedAt is { } at ? IsoTime.Format(at) : null,
        });

    private static MappingRegistry People(MappingRegistry registry) => registry
        .Add<BookingSummary, RecentBookingView>((b, _) => new RecentBookingView
        {
            Id = b.Id,
            Number = b.Number,
            Status = b.Status,
            ServiceName = b.ServiceName,
            Total = b.TotalPaisa,
            CreatedAt = IsoTime.Format(b.CreatedAt),
        })
        .Add<VerificationItem, VerificationItemView>((it, _) => new VerificationItemView
        {
            Type = it.Type,
            Status = it.Status,
            Required = it.Required,
            RejectionReason = it.Reason.Length == 0 ? null : it.Reason,
            DecidedAt = it.DecidedAt is { } d ? IsoTime.Format(d) : null,
            ExpiresAt = it.ExpiresAt is { } e ? IsoTime.Format(e) : null,
        })
        .Add<MerchantWithServices, AdminProviderSummaryView>((m, _) => new AdminProviderSummaryView
        {
            Id = m.Record.Id,
            Name = m.Record.Name,
            Phone = m.Record.Phone,
            Status = m.Record.Status,
            Level = m.Record.Level,
            Services = m.Services,
            Rating = m.Record.Rating,
            CompletedJobs = m.Record.CompletedJobs,
            FlaggedForReview = m.Record.Flagged,
            Online = m.Record.Online,
            CreatedAt = IsoTime.Format(m.Record.CreatedAt),
        });

    private static MappingRegistry Customers(MappingRegistry registry) => registry
        .Add<CustomerRecord, AdminCustomerSummaryView>((c, _) => new AdminCustomerSummaryView
        {
            Id = c.Id,
            Name = c.Name,
            Phone = c.Phone,
            Status = c.Status,
            Bookings = c.Bookings,
            CreatedAt = IsoTime.Format(c.CreatedAt),
        });
}
