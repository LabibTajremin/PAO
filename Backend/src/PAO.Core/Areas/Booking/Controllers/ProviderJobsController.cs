using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Booking.Features.Progress.Commands;
using PAO.Core.Areas.Booking.Features.Read.Queries;
using PAO.Core.Areas.Booking.Features.Respond.Commands;
using PAO.Core.Areas.Booking.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Controllers;

/// <summary>A provider's jobs, from the request to the receipt (P-04 to P-09).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/provider/jobs")]
[ErrorMap(typeof(BookingErrorMap))]
public sealed class ProviderJobsController(IMediator mediator) : ControllerBase
{
    private Guid Me => HttpContext.Caller().AccountId;

    /// <summary>listProviderJobs.</summary>
    [HttpGet]
    [Merchant(Permission = "job:read:own")]
    public Task<BookingListView> List([FromQuery] string tab, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListBookings(Me, Side.Provider, tab, cursor, limit), HttpContext.RequestAborted);

    /// <summary>getProviderJob.</summary>
    [HttpGet("{bookingId}")]
    [Merchant(Permission = "job:read:own")]
    public Task<BookingView> Get(Guid bookingId) => mediator.Send(new GetBooking(Me, Side.Provider, bookingId), HttpContext.RequestAborted);

    /// <summary>acceptRequest.</summary>
    [HttpPost("{bookingId}/accept")]
    [Merchant(Permission = "job:respond")]
    public Task<BookingView> Accept(Guid bookingId) => mediator.Send(new AcceptBooking(Me, bookingId), HttpContext.RequestAborted);

    /// <summary>rejectRequest.</summary>
    [HttpPost("{bookingId}/reject")]
    [Merchant(Permission = "job:respond")]
    public Task<BookingView> Reject(Guid bookingId, [FromBody] ReasonInput body) =>
        mediator.Send(new RejectBooking(Me, bookingId, body), HttpContext.RequestAborted);

    /// <summary>markOnTheWay.</summary>
    [HttpPost("{bookingId}/on-the-way")]
    [Merchant(Permission = "job:progress")]
    public Task<BookingView> OnTheWay(Guid bookingId) =>
        mediator.Send(new AdvanceJob(Me, bookingId, BookingStatus.OnTheWay), HttpContext.RequestAborted);

    /// <summary>markArrived.</summary>
    [HttpPost("{bookingId}/arrived")]
    [Merchant(Permission = "job:progress")]
    public Task<BookingView> Arrived(Guid bookingId) =>
        mediator.Send(new AdvanceJob(Me, bookingId, BookingStatus.Arrived), HttpContext.RequestAborted);

    /// <summary>startJob.</summary>
    [HttpPost("{bookingId}/start")]
    [Merchant(Permission = "job:progress")]
    public Task<BookingView> Start(Guid bookingId, [FromBody] StartCodeInput body) =>
        mediator.Send(new StartJob(Me, bookingId, body.Code), HttpContext.RequestAborted);

    /// <summary>proposeExtras.</summary>
    [HttpPost("{bookingId}/extras")]
    [Merchant(Permission = "job:progress")]
    public Task<BookingView> Extras(Guid bookingId, [FromBody] ExtrasInput body) =>
        mediator.Send(new ProposeExtras(Me, bookingId, body), HttpContext.RequestAborted);

    /// <summary>completeJob.</summary>
    [HttpPost("{bookingId}/complete")]
    [Merchant(Permission = "job:progress")]
    public Task<BookingView> Complete(Guid bookingId, [FromBody] CompleteInput body) =>
        mediator.Send(new CompleteJob(Me, bookingId, body.CashReceived), HttpContext.RequestAborted);

    /// <summary>cancelProviderJob.</summary>
    [HttpPost("{bookingId}/cancel")]
    [Merchant(Permission = "job:respond")]
    public Task<BookingView> Cancel(Guid bookingId, [FromBody] ReasonInput body) =>
        mediator.Send(new CancelBooking(Side.Provider, Me, bookingId, body), HttpContext.RequestAborted);

    /// <summary>getProviderReceipt.</summary>
    [HttpGet("{bookingId}/receipt")]
    [Merchant(Permission = "job:read:own")]
    public Task<ReceiptView> Receipt(Guid bookingId) => mediator.Send(new GetReceipt(Me, bookingId), HttpContext.RequestAborted);
}
