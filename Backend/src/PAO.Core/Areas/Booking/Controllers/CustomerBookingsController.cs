using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Booking.Features.Progress.Commands;
using PAO.Core.Areas.Booking.Features.Read.Queries;
using PAO.Core.Areas.Booking.Features.Requests.Commands;
using PAO.Core.Areas.Booking.Features.Respond.Commands;
using PAO.Core.Areas.Booking.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Controllers;

/// <summary>A customer's bookings (C-06 to C-13).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/customer/bookings")]
[ErrorMap(typeof(BookingErrorMap))]
public sealed class CustomerBookingsController(IMediator mediator) : ControllerBase
{
    /// <summary>createBooking.</summary>
    [HttpPost]
    [Customer(Permission = "booking:create")]
    public async Task<IActionResult> Create([FromHeader(Name = "Idempotency-Key")] string? key, [FromBody] BookingCreateInput body) =>
        StatusCode(201, await mediator.Send(new CreateBooking(HttpContext.Caller().AccountId, key ?? string.Empty, body), HttpContext.RequestAborted));

    /// <summary>listCustomerBookings.</summary>
    [HttpGet]
    [Customer(Permission = "booking:read:own")]
    public Task<BookingListView> List([FromQuery] string tab, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListBookings(HttpContext.Caller().AccountId, Side.Customer, tab, cursor, limit), HttpContext.RequestAborted);

    /// <summary>getCustomerBooking.</summary>
    [HttpGet("{bookingId}")]
    [Customer(Permission = "booking:read:own")]
    public Task<BookingView> Get(Guid bookingId) =>
        mediator.Send(new GetBooking(HttpContext.Caller().AccountId, Side.Customer, bookingId), HttpContext.RequestAborted);

    /// <summary>getStartCode.</summary>
    [HttpGet("{bookingId}/start-code")]
    [Customer(Permission = "booking:read:own")]
    public Task<StartCodeView> StartCode(Guid bookingId) =>
        mediator.Send(new GetStartCode(HttpContext.Caller().AccountId, bookingId), HttpContext.RequestAborted);

    /// <summary>cancelCustomerBooking.</summary>
    [HttpPost("{bookingId}/cancel")]
    [Customer(Permission = "booking:cancel:own")]
    public Task<BookingView> Cancel(Guid bookingId, [FromBody] ReasonInput body) =>
        mediator.Send(new CancelBooking(Side.Customer, HttpContext.Caller().AccountId, bookingId, body), HttpContext.RequestAborted);

    /// <summary>decideExtras.</summary>
    [HttpPost("{bookingId}/extras/decision")]
    [Customer(Permission = "booking:update:own")]
    public Task<BookingView> Decide(Guid bookingId, [FromBody] ExtrasDecisionInput body) =>
        mediator.Send(new DecideExtras(HttpContext.Caller().AccountId, bookingId, body), HttpContext.RequestAborted);

    /// <summary>getCustomerReceipt.</summary>
    [HttpGet("{bookingId}/receipt")]
    [Customer(Permission = "booking:read:own")]
    public Task<ReceiptView> Receipt(Guid bookingId) =>
        mediator.Send(new GetReceipt(HttpContext.Caller().AccountId, bookingId), HttpContext.RequestAborted);
}
