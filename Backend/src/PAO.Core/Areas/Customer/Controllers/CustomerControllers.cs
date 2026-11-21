using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Customer.Features.Addresses.Commands;
using PAO.Core.Areas.Customer.Features.Addresses.Queries;
using PAO.Core.Areas.Customer.Features.Profile.Commands;
using PAO.Core.Areas.Customer.Features.Profile.Queries;
using PAO.Core.Areas.Customer.Features.ServiceArea.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Controllers;

/// <summary>Customer failures as API errors, with the codes and messages existing clients rely on.</summary>
public sealed class CustomerErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [CustomerErrors.NotFound] = new(404, "PROFILE_NOT_FOUND", "Set up your profile first."),
        [CustomerErrors.AddressNotFound] = ApiErrors.NotFound,
        [CustomerReasons.Invalid] = new(422, "VALIDATION_FAILED", "Check the details and try again."),
        [CustomerReasons.InvalidPhoto] = new(422, "UPLOAD_INVALID", "Upload the photo again."),
        [CustomerReasons.OutsideCountry] = new(422, "OUTSIDE_SERVICE_AREA", "Place the pin inside Bangladesh."),
        [CustomerReasons.AddressLimit] = new(409, "ADDRESS_LIMIT_REACHED", "You can save up to 10 addresses. Delete one first."),
        [CustomerReasons.ProfileRequired] = new(409, "PROFILE_REQUIRED", "Set up your profile first."),
    };
}

/// <summary>The customer's own profile (C-01).</summary>
[ApiController]
[Area("Customer")]
[Route("v1/customer/profile")]
[ErrorMap(typeof(CustomerErrorMap))]
[Customer(Permission = "profile:manage:own")]
public sealed class CustomerProfileController(IMediator mediator) : ControllerBase
{
    /// <summary>getCustomerProfile.</summary>
    [HttpGet]
    public Task<CustomerProfileView> Get() =>
        mediator.Send(new GetCustomerProfile(HttpContext.Caller().AccountId), HttpContext.RequestAborted);

    /// <summary>updateCustomerProfile.</summary>
    [HttpPut]
    public Task<CustomerProfileView> Update([FromBody] CustomerProfileInput body) =>
        mediator.Send(new SaveCustomerProfile(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted);
}

/// <summary>Saved addresses (C-02).</summary>
[ApiController]
[Area("Customer")]
[Route("v1/customer/addresses")]
[ErrorMap(typeof(CustomerErrorMap))]
[Customer(Permission = "address:manage:own")]
public sealed class AddressesController(IMediator mediator) : ControllerBase
{
    /// <summary>listAddresses.</summary>
    [HttpGet]
    public Task<AddressListView> List() => mediator.Send(new ListAddresses(HttpContext.Caller().AccountId), HttpContext.RequestAborted);

    /// <summary>createAddress.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] AddressInput body) =>
        StatusCode(201, await mediator.Send(new AddAddress(HttpContext.Caller().AccountId, body), HttpContext.RequestAborted));

    /// <summary>updateAddress.</summary>
    [HttpPut("{addressId}")]
    public Task<AddressView> Update(Guid addressId, [FromBody] AddressInput body) =>
        mediator.Send(new UpdateAddress(HttpContext.Caller().AccountId, addressId, body), HttpContext.RequestAborted);

    /// <summary>deleteAddress.</summary>
    [HttpDelete("{addressId}")]
    public async Task<IActionResult> Delete(Guid addressId)
    {
        await mediator.Send(new DeleteAddress(HttpContext.Caller().AccountId, addressId), HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>setDefaultAddress.</summary>
    [HttpPost("{addressId}/default")]
    public Task<AddressView> SetDefault(Guid addressId) =>
        mediator.Send(new SetDefaultAddress(HttpContext.Caller().AccountId, addressId), HttpContext.RequestAborted);
}

/// <summary>The launch-area check (C35).</summary>
[ApiController]
[Area("Customer")]
[Route("v1/customer/service-area")]
[ErrorMap(typeof(CustomerErrorMap))]
public sealed class ServiceAreaController(IMediator mediator) : ControllerBase
{
    /// <summary>checkServiceArea.</summary>
    [HttpGet]
    [AllUserType(Permission = "catalog:read")]
    public Task<ServiceAreaCheckView> Check([FromQuery] double lat, [FromQuery] double lng) =>
        mediator.Send(new CheckServiceArea(new GeoPoint { Lat = lat, Lng = lng }), HttpContext.RequestAborted);
}
