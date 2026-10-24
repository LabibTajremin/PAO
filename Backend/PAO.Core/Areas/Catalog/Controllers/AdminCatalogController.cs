using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Catalog.Features.ManageCatalog.Commands;
using PAO.Core.Areas.Catalog.Features.ManageCatalog.Queries;
using PAO.Core.Areas.Catalog.Features.Prices.Commands;
using PAO.Core.Areas.Catalog.Features.Prices.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Controllers;

/// <summary>Catalog and price management for admins (A-02, A03).</summary>
[ApiController]
[Area("Catalog")]
[Route("v1/admin/catalog")]
[ErrorMap(typeof(CatalogErrorMap))]
[Admin(Permission = "catalog:manage")]
public sealed class AdminCatalogController(IMediator mediator) : ControllerBase
{
    /// <summary>getAdminCatalog.</summary>
    [HttpGet]
    public Task<CatalogTreeView> Catalog() => mediator.Send(new GetAdminCatalog(), HttpContext.RequestAborted);

    /// <summary>createCategory.</summary>
    [HttpPost("categories")]
    public async Task<IActionResult> CreateCategory([FromBody] CategoryInput body) =>
        StatusCode(201, await mediator.Send(new SaveCategory(null, body), HttpContext.RequestAborted));

    /// <summary>updateCategory.</summary>
    [HttpPut("categories/{categoryId}")]
    public Task<CategoryView> UpdateCategory(Guid categoryId, [FromBody] CategoryInput body) =>
        mediator.Send(new SaveCategory(categoryId, body), HttpContext.RequestAborted);

    /// <summary>createService.</summary>
    [HttpPost("services")]
    public async Task<IActionResult> CreateService([FromBody] ServiceInput body) =>
        StatusCode(201, await mediator.Send(new SaveService(null, body), HttpContext.RequestAborted));

    /// <summary>updateService.</summary>
    [HttpPut("services/{serviceId}")]
    public Task<ServiceView> UpdateService(Guid serviceId, [FromBody] ServiceInput body) =>
        mediator.Send(new SaveService(serviceId, body), HttpContext.RequestAborted);

    /// <summary>createSubService; the input schema serves updates too, so `initialPrice` is optional there.</summary>
    [HttpPost("sub-services")]
    public async Task<IActionResult> CreateSubService([FromBody] SubServiceInput body) =>
        StatusCode(201, await mediator.Send(new CreateSubService(body, HttpContext.Caller().AccountId), HttpContext.RequestAborted));

    /// <summary>updateSubService.</summary>
    [HttpPut("sub-services/{subServiceId}")]
    public Task<SubServiceView> UpdateSubService(Guid subServiceId, [FromBody] SubServiceInput body) =>
        mediator.Send(new UpdateSubService(subServiceId, body), HttpContext.RequestAborted);

    /// <summary>changePrice.</summary>
    [HttpPost("sub-services/{subServiceId}/prices")]
    public async Task<IActionResult> ChangePrice(Guid subServiceId, [FromBody] PriceInput body) =>
        StatusCode(201, await mediator.Send(new ChangePrice(subServiceId, body.Amount, HttpContext.Caller().AccountId), HttpContext.RequestAborted));

    /// <summary>listPriceHistory.</summary>
    [HttpGet("sub-services/{subServiceId}/prices")]
    public Task<PriceHistoryView> PriceHistory(Guid subServiceId) =>
        mediator.Send(new ListPriceHistory(subServiceId), HttpContext.RequestAborted);
}
