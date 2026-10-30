using FluentValidation;
using PAO.Core.Areas.Admin.Services;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.People.Queries;

/// <summary>Providers for the admin console, newest first (A-05).</summary>
public sealed record ListAdminProviders(PeopleQuery Query) : IQuery<PageView<AdminProviderSummaryView>>;

/// <summary>Customers for the admin console, newest first (A-05).</summary>
public sealed record ListAdminCustomers(PeopleQuery Query) : IQuery<PageView<AdminCustomerSummaryView>>;

/// <summary>One provider's record, verification, bookings and history.</summary>
public sealed record GetAdminProvider(Guid ProviderId) : IQuery<AdminProviderDetailView>;

/// <summary>One customer's record, rating, bookings, complaints and history.</summary>
public sealed record GetAdminCustomer(Guid CustomerId) : IQuery<AdminCustomerDetailView>;

/// <summary>Checks <see cref="ListAdminProviders"/>.</summary>
public sealed class ListAdminProvidersValidator : AbstractValidator<ListAdminProviders>
{
    /// <summary>The spec has checked the formats.</summary>
    public ListAdminProvidersValidator() => RuleFor(r => r.Query).NotNull();
}

/// <summary>Checks <see cref="ListAdminCustomers"/>.</summary>
public sealed class ListAdminCustomersValidator : AbstractValidator<ListAdminCustomers>
{
    /// <summary>The spec has checked the formats.</summary>
    public ListAdminCustomersValidator() => RuleFor(r => r.Query).NotNull();
}

/// <summary>Answers <see cref="ListAdminProviders"/>.</summary>
public sealed class ListAdminProvidersHandler(AdminPeers peers, AdminConsole console) : IRequestHandler<ListAdminProviders, PageView<AdminProviderSummaryView>>
{
    /// <inheritdoc />
    public async Task<PageView<AdminProviderSummaryView>> Handle(ListAdminProviders request, CancellationToken cancellationToken)
    {
        var q = request.Query;
        var size = Cursor.PageSize(q.Limit);
        var (at, id) = ComplaintSteps.After(q.Cursor);
        var rows = await peers.Merchants.SearchMerchants(new MerchantQuery
        {
            Text = q.Text ?? string.Empty,
            Status = q.Status ?? string.Empty,
            Level = q.Level,
            Flagged = q.Flagged,
            AfterAt = at,
            AfterId = id,
            Limit = size + 1,
        }, cancellationToken);
        var page = ComplaintSteps.Page(rows, size, r => (r.CreatedAt, r.Id), shown => shown);
        return new PageView<AdminProviderSummaryView> { Items = await console.ProviderRows(page.Items, cancellationToken), NextCursor = page.NextCursor };
    }
}

/// <summary>Answers <see cref="ListAdminCustomers"/>.</summary>
public sealed class ListAdminCustomersHandler(AdminPeers peers, IMapper mapper) : IRequestHandler<ListAdminCustomers, PageView<AdminCustomerSummaryView>>
{
    /// <inheritdoc />
    public async Task<PageView<AdminCustomerSummaryView>> Handle(ListAdminCustomers request, CancellationToken cancellationToken)
    {
        var q = request.Query;
        var size = Cursor.PageSize(q.Limit);
        var (at, id) = ComplaintSteps.After(q.Cursor);
        var rows = await peers.Customers.SearchCustomers(new CustomerQuery
        {
            Text = q.Text ?? string.Empty,
            Status = q.Status ?? string.Empty,
            AfterAt = at,
            AfterId = id,
            Limit = size + 1,
        }, cancellationToken);
        return ComplaintSteps.Page(rows, size, r => (r.CreatedAt, r.Id), mapper.MapAll<CustomerRecord, AdminCustomerSummaryView>);
    }
}

/// <summary>Answers <see cref="GetAdminProvider"/>.</summary>
public sealed class GetAdminProviderHandler(AdminConsole console) : IRequestHandler<GetAdminProvider, AdminProviderDetailView>
{
    /// <inheritdoc />
    public Task<AdminProviderDetailView> Handle(GetAdminProvider request, CancellationToken cancellationToken) => console.Provider(request.ProviderId, null, cancellationToken);
}

/// <summary>Answers <see cref="GetAdminCustomer"/>.</summary>
public sealed class GetAdminCustomerHandler(AdminConsole console) : IRequestHandler<GetAdminCustomer, AdminCustomerDetailView>
{
    /// <inheritdoc />
    public Task<AdminCustomerDetailView> Handle(GetAdminCustomer request, CancellationToken cancellationToken) => console.Customer(request.CustomerId, null, cancellationToken);
}
