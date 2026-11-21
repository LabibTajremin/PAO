using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Admin.Features.Dashboard.Queries;
using PAO.Core.Areas.Admin.Features.People.Commands;
using PAO.Core.Areas.Admin.Features.People.Queries;
using PAO.Core.Areas.Admin.Features.Settings.Commands;
using PAO.Core.Areas.Admin.Features.Settings.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Controllers;

/// <summary>Platform settings (A-10).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/settings")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class SettingsController(IMediator mediator) : ControllerBase
{
    /// <summary>listSettings.</summary>
    [HttpGet]
    [Admin(Permission = "settings:read")]
    public Task<SettingListView> List() => mediator.Send(new ListSettings(), HttpContext.RequestAborted);

    /// <summary>updateSetting.</summary>
    [HttpPut("{key}")]
    [Admin(Permission = "settings:manage")]
    public Task<SettingView> Update(string key, [FromBody] SettingUpdateInput body) =>
        mediator.Send(new UpdateSetting(HttpContext.Caller().AccountId, key, body.Value), HttpContext.RequestAborted);
}

/// <summary>The admin home numbers (A-09).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/dashboard")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class DashboardController(IMediator mediator) : ControllerBase
{
    /// <summary>getDashboard.</summary>
    [HttpGet]
    [Admin(Permission = "dashboard:read")]
    public Task<DashboardView> Get() => mediator.Send(new GetDashboard(), HttpContext.RequestAborted);
}

/// <summary>Provider search, detail and status (A-05).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/providers")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class AdminProvidersController(IMediator mediator) : ControllerBase
{
    /// <summary>listAdminProviders.</summary>
    [HttpGet]
    [Admin(Permission = "provider:read")]
    public Task<PageView<AdminProviderSummaryView>> List(
        [FromQuery] string? q, [FromQuery] string? status, [FromQuery] int? level, [FromQuery] bool? flagged, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListAdminProviders(new PeopleQuery(q, status, level, flagged, cursor, limit)), HttpContext.RequestAborted);

    /// <summary>getAdminProvider.</summary>
    [HttpGet("{providerId}")]
    [Admin(Permission = "provider:read")]
    public Task<AdminProviderDetailView> Get(Guid providerId) => mediator.Send(new GetAdminProvider(providerId), HttpContext.RequestAborted);

    /// <summary>changeProviderStatus.</summary>
    [HttpPost("{providerId}/status")]
    [Admin(Permission = "provider:manage")]
    public Task<AdminProviderDetailView> SetStatus(Guid providerId, [FromBody] AccountStatusInput body) =>
        mediator.Send(new ChangeProviderStatus(new StatusChange(HttpContext.Caller().AccountId, providerId, body.Status, body.Reason)), HttpContext.RequestAborted);
}

/// <summary>Customer search, detail and status (A-05).</summary>
[ApiController]
[Area("Admin")]
[Route("v1/admin/customers")]
[ErrorMap(typeof(AdminErrorMap))]
public sealed class AdminCustomersController(IMediator mediator) : ControllerBase
{
    /// <summary>listAdminCustomers.</summary>
    [HttpGet]
    [Admin(Permission = "customer:read")]
    public Task<PageView<AdminCustomerSummaryView>> List([FromQuery] string? q, [FromQuery] string? status, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListAdminCustomers(new PeopleQuery(q, status, null, null, cursor, limit)), HttpContext.RequestAborted);

    /// <summary>getAdminCustomer.</summary>
    [HttpGet("{customerId}")]
    [Admin(Permission = "customer:read")]
    public Task<AdminCustomerDetailView> Get(Guid customerId) => mediator.Send(new GetAdminCustomer(customerId), HttpContext.RequestAborted);

    /// <summary>changeCustomerStatus.</summary>
    [HttpPost("{customerId}/status")]
    [Admin(Permission = "customer:manage")]
    public Task<AdminCustomerDetailView> SetStatus(Guid customerId, [FromBody] AccountStatusInput body) =>
        mediator.Send(new ChangeCustomerStatus(new StatusChange(HttpContext.Caller().AccountId, customerId, body.Status, body.Reason)), HttpContext.RequestAborted);
}
