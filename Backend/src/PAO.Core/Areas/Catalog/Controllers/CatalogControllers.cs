using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Catalog.Features.Browse.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Controllers;

/// <summary>Catalog failures as API errors, with the codes and messages existing clients rely on.</summary>
public sealed class CatalogErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [CatalogReasons.NotFound] = ApiErrors.NotFound,
        [CatalogReasons.Invalid] = ApiErrors.ValidationFailed,
        [CatalogReasons.PriceNegative] = ApiErrors.Validation("field", "amount"),
    };
}

/// <summary>Browsing and search for the customer app (C-03, C08, C09).</summary>
[ApiController]
[Area("Catalog")]
[Route("v1/customer")]
[ErrorMap(typeof(CatalogErrorMap))]
public sealed class CustomerCatalogController(IMediator mediator) : ControllerBase
{
    /// <summary>getCatalog.</summary>
    [HttpGet("catalog")]
    [AllUserType(Permission = "catalog:read")]
    public Task<CatalogTreeView> Catalog() => mediator.Send(new GetPublishedCatalog(), HttpContext.RequestAborted);

    /// <summary>searchCatalog.</summary>
    [HttpGet("catalog/search")]
    [AllUserType(Permission = "catalog:read")]
    public Task<CatalogSearchView> Search([FromQuery] string q) => mediator.Send(new SearchCatalog(q), HttpContext.RequestAborted);

    /// <summary>getService.</summary>
    [HttpGet("services/{serviceId}")]
    [AllUserType(Permission = "catalog:read")]
    public Task<ServiceView> Service(Guid serviceId) => mediator.Send(new GetPublishedService(serviceId), HttpContext.RequestAborted);
}

/// <summary>The published catalog for the partner app, e.g. to pick services at enrolment.</summary>
[ApiController]
[Area("Catalog")]
[Route("v1/provider/catalog")]
[ErrorMap(typeof(CatalogErrorMap))]
public sealed class MerchantCatalogController(IMediator mediator) : ControllerBase
{
    /// <summary>getProviderCatalog.</summary>
    [HttpGet]
    [AllUserType(Permission = "catalog:read")]
    public Task<CatalogTreeView> Catalog() => mediator.Send(new GetPublishedCatalog(), HttpContext.RequestAborted);
}
