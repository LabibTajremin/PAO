using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Booking.Features.Discovery.Queries;
using PAO.Core.Areas.Booking.Features.Earnings.Queries;
using PAO.Core.Areas.Booking.Features.Monitor.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Controllers;

/// <summary>Booking failures as API errors, equal to the Go and NestJS map.</summary>
public sealed class BookingErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [BookingReasons.NotFound] = ApiErrors.NotFound,
        [BookingReasons.Invalid] = new(422, "VALIDATION_FAILED", "Check the booking details."),
        [BookingReasons.InvalidTransition] = new(409, "BOOKING_INVALID_TRANSITION", "The booking has moved on."),
        [BookingReasons.DeadlinePassed] = new(409, "ACCEPT_DEADLINE_PASSED", "The time to answer has passed."),
        [BookingReasons.ActiveJob] = new(409, "ACTIVE_JOB_EXISTS", "Finish your current job first."),
        [BookingReasons.CodeWrong] = new(422, "START_CODE_INVALID", "The start code is wrong."),
        [BookingReasons.CodeLocked] = new(409, "START_CODE_LOCKED", "Too many wrong codes. Try again later."),
        [BookingReasons.CashNotConfirmed] = new(422, "CASH_CONFIRMATION_REQUIRED", "Confirm that you received the cash."),
        [BookingReasons.ExtrasPending] = new(409, "EXTRAS_PENDING", "The customer has not answered the extra items yet."),
        [BookingReasons.NoProposal] = new(409, "NO_PENDING_EXTRAS", "There are no extra items waiting."),
        [BookingReasons.NotBookable] = new(409, "PROVIDER_UNAVAILABLE", "This provider cannot take the booking now."),
        [BookingReasons.DuplicateRequest] = new(409, "DUPLICATE_BOOKING_REQUEST", "You already asked this provider."),
        [BookingReasons.CancelNotAllowed] = new(409, "CANCELLATION_NOT_ALLOWED", "The job has started; report a problem instead."),
        [BookingReasons.OutsideArea] = new(422, "OUTSIDE_SERVICE_AREA", "This address is outside our service area."),
        [BookingReasons.ProfileRequired] = new(409, "PROFILE_REQUIRED", "Set up your profile first."),
    };
}

/// <summary>Providers around the customer with the fixed price of the job (C10).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/customer/providers/nearby")]
[ErrorMap(typeof(BookingErrorMap))]
public sealed class NearbyController(IMediator mediator) : ControllerBase
{
    /// <summary>findNearbyProviders.</summary>
    [HttpGet]
    [Customer(Permission = "provider:browse")]
    public Task<NearbyProvidersView> Find(
        [FromQuery] Guid serviceId, [FromQuery] Guid subServiceId, [FromQuery] int quantity, [FromQuery] Guid? addressId,
        [FromQuery] double? lat, [FromQuery] double? lng, [FromQuery] string? sort, [FromQuery] int? limit) =>
        mediator.Send(new FindNearbyProviders(HttpContext.Caller().AccountId, new NearbyInput
        {
            ServiceId = serviceId,
            SubServiceId = subServiceId,
            Quantity = quantity,
            AddressId = addressId,
            Lat = lat,
            Lng = lng,
            Sort = sort,
            Limit = limit,
        }), HttpContext.RequestAborted);
}

/// <summary>The admin bookings monitor (A-06; ADR-0026 has Booking serve it).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/admin/bookings")]
[ErrorMap(typeof(BookingErrorMap))]
[Admin(Permission = "booking:read:any")]
public sealed class AdminBookingsController(IMediator mediator) : ControllerBase
{
    /// <summary>listAdminBookings.</summary>
    [HttpGet]
    public Task<BookingListView> List(
        [FromQuery] string? status, [FromQuery] Guid? serviceId, [FromQuery] string? from, [FromQuery] string? to,
        [FromQuery] string? area, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new MonitorBookings(new MonitorInput
        {
            Status = status,
            ServiceId = serviceId,
            From = from,
            To = to,
            Area = area,
            Cursor = cursor,
            Limit = limit,
        }), HttpContext.RequestAborted);

    /// <summary>getAdminBooking.</summary>
    [HttpGet("{bookingId}")]
    public Task<BookingView> Get(Guid bookingId) => mediator.Send(new GetSupportBooking(bookingId), HttpContext.RequestAborted);
}

/// <summary>The provider's earnings per Asia/Dhaka day (P-08).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/provider/earnings")]
[ErrorMap(typeof(BookingErrorMap))]
[Merchant(Permission = "earnings:read:own")]
public sealed class EarningsController(IMediator mediator) : ControllerBase
{
    /// <summary>getEarningsSummary.</summary>
    [HttpGet("summary")]
    public Task<EarningsSummaryView> Summary([FromQuery] string period, [FromQuery] string? date) =>
        mediator.Send(new GetEarningsSummary(HttpContext.Caller().AccountId, period, date), HttpContext.RequestAborted);

    /// <summary>listEarningsJobs.</summary>
    [HttpGet("jobs")]
    public Task<EarningsJobListView> Jobs([FromQuery] string? from, [FromQuery] string? to, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListEarningsJobs(HttpContext.Caller().AccountId, from, to, cursor, limit), HttpContext.RequestAborted);
}
