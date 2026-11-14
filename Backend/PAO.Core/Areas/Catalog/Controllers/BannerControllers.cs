using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Catalog.Features.Banners.Commands;
using PAO.Core.Areas.Catalog.Features.Banners.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Controllers;

/// <summary>Home banner management for admins (C07 content).</summary>
[ApiController]
[Area("Catalog")]
[Route("v1/admin/catalog/banners")]
[ErrorMap(typeof(CatalogErrorMap))]
[Admin(Permission = "catalog:manage")]
public sealed class AdminBannersController(IMediator mediator) : ControllerBase
{
    /// <summary>listBanners.</summary>
    [HttpGet]
    public Task<BannerListView> List() => mediator.Send(new ListBanners(PublishedOnly: false), HttpContext.RequestAborted);

    /// <summary>createBanner.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] BannerInput body) =>
        StatusCode(201, await mediator.Send(new SaveBanner(null, body), HttpContext.RequestAborted));

    /// <summary>updateBanner.</summary>
    [HttpPut("{bannerId}")]
    public Task<BannerView> Update(Guid bannerId, [FromBody] BannerInput body) =>
        mediator.Send(new SaveBanner(bannerId, body), HttpContext.RequestAborted);

    /// <summary>deleteBanner.</summary>
    [HttpDelete("{bannerId}")]
    public async Task<IActionResult> Delete(Guid bannerId)
    {
        await mediator.Send(new DeleteBanner(bannerId), HttpContext.RequestAborted);
        return NoContent();
    }
}

/// <summary>The published home banners for the customer app (C07).</summary>
[ApiController]
[Area("Catalog")]
[Route("v1/customer/banners")]
[ErrorMap(typeof(CatalogErrorMap))]
public sealed class CustomerBannersController(IMediator mediator) : ControllerBase
{
    /// <summary>getBanners.</summary>
    [HttpGet]
    [AllUserType(Permission = "catalog:read")]
    public Task<BannerListView> List() => mediator.Send(new ListBanners(PublishedOnly: true), HttpContext.RequestAborted);
}
