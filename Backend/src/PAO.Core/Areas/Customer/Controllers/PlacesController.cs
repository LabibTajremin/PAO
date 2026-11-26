using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Customer.Features.Places.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Controllers;

/// <summary>OpenStreetMap place lookups for the map pickers (ADR-0042); every signed-in app may ask.</summary>
[ApiController]
[Area("Customer")]
[Route("v1/places")]
[ErrorMap(typeof(CustomerErrorMap))]
public sealed class PlacesController(IMediator mediator) : ControllerBase
{
    /// <summary>searchPlaces.</summary>
    [HttpGet("search")]
    [AllUserType(Permission = "catalog:read")]
    public Task<PlaceListView> Search([FromQuery] string q, [FromQuery] double? lat, [FromQuery] double? lng, [FromQuery] string? lang) =>
        mediator.Send(new SearchPlaces(q, lat is { } a && lng is { } b ? new GeoPoint { Lat = a, Lng = b } : null, lang ?? "en"), HttpContext.RequestAborted);

    /// <summary>reversePlace.</summary>
    [HttpGet("reverse")]
    [AllUserType(Permission = "catalog:read")]
    public Task<PlaceView> Reverse([FromQuery] double lat, [FromQuery] double lng, [FromQuery] string? lang) =>
        mediator.Send(new ReversePlace(new GeoPoint { Lat = lat, Lng = lng }, lang ?? "en"), HttpContext.RequestAborted);
}
