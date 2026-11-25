using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Booking.Features.Subscriptions.Commands;
using PAO.Core.Areas.Booking.Features.Subscriptions.Queries;
using PAO.Core.Areas.Booking.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Controllers;

/// <summary>A customer's scheduled deliveries (ADR-0041).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/customer/subscriptions")]
[ErrorMap(typeof(BookingErrorMap))]
public sealed class CustomerSubscriptionsController(IMediator mediator) : ControllerBase
{
    private Guid Me => HttpContext.Caller().AccountId;

    /// <summary>createSubscription.</summary>
    [HttpPost]
    [Customer(Permission = "booking:create")]
    public async Task<IActionResult> Create([FromHeader(Name = "Idempotency-Key")] string? key, [FromBody] SubscriptionCreateInput body) =>
        StatusCode(201, await mediator.Send(new CreateSubscription(Me, key ?? string.Empty, body), HttpContext.RequestAborted));

    /// <summary>listCustomerSubscriptions.</summary>
    [HttpGet]
    [Customer(Permission = "booking:read:own")]
    public Task<SubscriptionListView> List() =>
        mediator.Send(new ListSubscriptions(new(Side.Customer, Me, null)), HttpContext.RequestAborted);

    /// <summary>getCustomerSubscription.</summary>
    [HttpGet("{subscriptionId}")]
    [Customer(Permission = "booking:read:own")]
    public Task<SubscriptionView> Get(Guid subscriptionId) =>
        mediator.Send(new GetSubscription(new(Side.Customer, Me, null), subscriptionId), HttpContext.RequestAborted);

    /// <summary>pauseSubscription.</summary>
    [HttpPost("{subscriptionId}/pause")]
    [Customer(Permission = "booking:update:own")]
    public Task<SubscriptionView> Pause(Guid subscriptionId) => Set(subscriptionId, SubscriptionStatus.Paused);

    /// <summary>resumeSubscription.</summary>
    [HttpPost("{subscriptionId}/resume")]
    [Customer(Permission = "booking:update:own")]
    public Task<SubscriptionView> Resume(Guid subscriptionId) => Set(subscriptionId, SubscriptionStatus.Active);

    /// <summary>cancelSubscription.</summary>
    [HttpPost("{subscriptionId}/cancel")]
    [Customer(Permission = "booking:cancel:own")]
    public Task<SubscriptionView> Cancel(Guid subscriptionId) => Set(subscriptionId, SubscriptionStatus.Cancelled);

    /// <summary>changeDelivery.</summary>
    [HttpPut("{subscriptionId}/deliveries/{date}")]
    [Customer(Permission = "booking:update:own")]
    public Task<DeliveryDateView> Change(Guid subscriptionId, DateOnly date, [FromBody] DeliveryChangeInput body) =>
        mediator.Send(new ChangeDelivery(Me, subscriptionId, date, body), HttpContext.RequestAborted);

    private Task<SubscriptionView> Set(Guid id, string status) =>
        mediator.Send(new SetSubscriptionStatus(Me, id, status), HttpContext.RequestAborted);
}

/// <summary>A merchant's scheduled deliveries: the inbox, the calendar and declining a date (ADR-0041).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/provider")]
[ErrorMap(typeof(BookingErrorMap))]
public sealed class ProviderSubscriptionsController(IMediator mediator) : ControllerBase
{
    private Guid Me => HttpContext.Caller().AccountId;

    /// <summary>listProviderSubscriptions.</summary>
    [HttpGet("subscriptions")]
    [Merchant(Permission = "job:read:own")]
    public Task<SubscriptionListView> List([FromQuery] string? status) =>
        mediator.Send(new ListSubscriptions(new(Side.Provider, Me, status)), HttpContext.RequestAborted);

    /// <summary>getProviderSubscription.</summary>
    [HttpGet("subscriptions/{subscriptionId}")]
    [Merchant(Permission = "job:read:own")]
    public Task<SubscriptionView> Get(Guid subscriptionId) =>
        mediator.Send(new GetSubscription(new(Side.Provider, Me, null), subscriptionId), HttpContext.RequestAborted);

    /// <summary>acceptSubscription.</summary>
    [HttpPost("subscriptions/{subscriptionId}/accept")]
    [Merchant(Permission = "job:respond")]
    public Task<SubscriptionView> Accept(Guid subscriptionId) =>
        mediator.Send(new AcceptSubscription(Me, subscriptionId), HttpContext.RequestAborted);

    /// <summary>declineSubscription.</summary>
    [HttpPost("subscriptions/{subscriptionId}/decline")]
    [Merchant(Permission = "job:respond")]
    public Task<SubscriptionView> Decline(Guid subscriptionId, [FromBody] ReasonInput body) =>
        mediator.Send(new DeclineSubscription(Me, subscriptionId, body), HttpContext.RequestAborted);

    /// <summary>declineDelivery.</summary>
    [HttpPost("subscriptions/{subscriptionId}/deliveries/{date}/decline")]
    [Merchant(Permission = "job:respond")]
    public Task<DeliveryDateView> DeclineDate(Guid subscriptionId, DateOnly date) =>
        mediator.Send(new DeclineDelivery(Me, subscriptionId, date), HttpContext.RequestAborted);

    /// <summary>listProviderDeliveries.</summary>
    [HttpGet("deliveries")]
    [Merchant(Permission = "job:read:own")]
    public Task<ProviderDeliveryListView> Deliveries([FromQuery] DateOnly from, [FromQuery] DateOnly to) =>
        mediator.Send(new ListProviderDeliveries(Me, from, to), HttpContext.RequestAborted);
}

/// <summary>Subscriptions in the bookings monitor (ADR-0041).</summary>
[ApiController]
[Area("Booking")]
[Route("v1/admin/subscriptions")]
[ErrorMap(typeof(BookingErrorMap))]
[Admin(Permission = "booking:read:any")]
public sealed class AdminSubscriptionsController(IMediator mediator) : ControllerBase
{
    /// <summary>listAdminSubscriptions.</summary>
    [HttpGet]
    public Task<SubscriptionListView> List([FromQuery] string? status) =>
        mediator.Send(new ListSubscriptions(new(Side.Any, null, status)), HttpContext.RequestAborted);

    /// <summary>getAdminSubscription.</summary>
    [HttpGet("{subscriptionId}")]
    public Task<SubscriptionView> Get(Guid subscriptionId) =>
        mediator.Send(new GetSubscription(new(Side.Any, null, null), subscriptionId), HttpContext.RequestAborted);
}
