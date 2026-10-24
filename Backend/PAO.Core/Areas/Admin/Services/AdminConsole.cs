using PAO.Core.Areas.Admin.Repositories;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>The admin provider and customer screens (A-05), read from the areas that own the data (ADR-0026).</summary>
public sealed class AdminConsole(AdminPeers peers, ComplaintRepository complaints, IMapper mapper)
{
    /// <summary>Bounds the status history on the detail screens.</summary>
    public const int HistorySize = 50;

    /// <summary>Bounds the recent bookings and complaints on the detail screens.</summary>
    public const int RecentSize = 10;

    /// <summary>Provider rows with their service names; the catalog's published list names them in one read.</summary>
    public async Task<IReadOnlyList<AdminProviderSummaryView>> ProviderRows(IReadOnlyList<MerchantRecord> rows, CancellationToken cancellationToken)
    {
        var names = (await peers.Catalog.ListServices(cancellationToken)).ToDictionary(s => s.Id, s => new ServiceRefView { Id = s.Id, Name = s.Name });
        return mapper.MapAll<MerchantWithServices, AdminProviderSummaryView>(
            rows.Select(r => new MerchantWithServices(r, [.. r.ServiceIds.Where(names.ContainsKey).Select(id => names[id])])));
    }

    /// <summary>One provider's record, verification, bookings and history; `status` shows a decision before the read model catches up.</summary>
    public async Task<AdminProviderDetailView> Provider(Guid id, string? status, CancellationToken cancellationToken)
    {
        var record = await ProviderRecord(id, cancellationToken);
        var summary = (await ProviderRows([record], cancellationToken))[0];
        var profile = await peers.Merchants.GetMerchant(id, cancellationToken);
        var items = await peers.Verification.GetItems(id, cancellationToken);
        var recent = await peers.Bookings.ListRecentBookings(id, RecentSize, cancellationToken);
        var against = await complaints.CountAgainst(id, cancellationToken);
        var stats = await peers.Bookings.GetMerchantStats(id, cancellationToken);
        var history = await peers.Audit.ListForSubject("account", id.ToString(), HistorySize, cancellationToken);
        return new AdminProviderDetailView
        {
            Summary = status is null ? summary : summary with { Status = status },
            Gender = profile.Gender.Length == 0 ? null : profile.Gender,
            ExperienceYears = profile.ExperienceYears,
            Items = mapper.MapAll<VerificationItem, VerificationItemView>(items),
            RecentBookings = mapper.MapAll<BookingSummary, RecentBookingView>(recent),
            Complaints = against,
            Cancellations30d = stats.Cancellations30d,
            StatusHistory = mapper.MapAll<AuditEntry, AuditEntryView>(history),
        };
    }

    /// <summary>One customer's record, rating, bookings, complaints and history; the rating shows once providers rated them.</summary>
    public async Task<AdminCustomerDetailView> Customer(Guid id, string? status, CancellationToken cancellationToken)
    {
        var record = await CustomerRecord(id, cancellationToken);
        var rating = await peers.Ratings.GetCustomerRating(id, cancellationToken);
        var recent = await peers.Bookings.ListRecentBookings(id, RecentSize, cancellationToken);
        var involving = await complaints.Involving(id, RecentSize, cancellationToken);
        var history = await peers.Audit.ListForSubject("account", id.ToString(), HistorySize, cancellationToken);
        var summary = mapper.Map<CustomerRecord, AdminCustomerSummaryView>(status is null ? record : record with { Status = status });
        return new AdminCustomerDetailView
        {
            Summary = rating.Count > 0 ? summary with { Rating = rating.Average } : summary,
            RecentBookings = mapper.MapAll<BookingSummary, RecentBookingView>(recent),
            Complaints = mapper.Views(involving),
            StatusHistory = mapper.MapAll<AuditEntry, AuditEntryView>(history),
        };
    }

    /// <summary>
    /// Suspends, bans or reinstates an account (A-05). Identity revokes sessions and blocks
    /// the phone; its status event takes a provider offline and blocks their NID (PRD §6.4).
    /// </summary>
    public Task SetStatus(StatusChange change, CancellationToken cancellationToken) =>
        peers.Identity.SetAccountStatus(new SetAccountStatusInput { AccountId = change.AccountId, Status = change.Status, Reason = change.Reason, ActorId = change.ActorId }, cancellationToken);

    /// <summary>The provider's list row; `admin.person_not_found` without one.</summary>
    public async Task<MerchantRecord> ProviderRecord(Guid id, CancellationToken cancellationToken) =>
        (await peers.Merchants.SearchMerchants(new MerchantQuery { Id = id, Text = string.Empty, Status = string.Empty, Limit = 1 }, cancellationToken))
            .FirstOrDefault() ?? throw new DomainException(AdminReasons.PersonNotFound);

    /// <summary>The customer's list row; `admin.person_not_found` without one.</summary>
    public async Task<CustomerRecord> CustomerRecord(Guid id, CancellationToken cancellationToken) =>
        (await peers.Customers.SearchCustomers(new CustomerQuery { Id = id, Text = string.Empty, Status = string.Empty, Limit = 1 }, cancellationToken))
            .FirstOrDefault() ?? throw new DomainException(AdminReasons.PersonNotFound);
}
