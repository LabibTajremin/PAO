using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Notification.Features.Devices.Commands;
using PAO.Core.Areas.Notification.Features.Inbox.Commands;
using PAO.Core.Areas.Notification.Features.Inbox.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Notification.Controllers;

/// <summary>Notification failures as API errors.</summary>
public sealed class NotificationErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [NotificationReasons.NotFound] = ApiErrors.NotFound,
    };
}

/// <summary>The customer app's inbox and device (C-13).</summary>
[ApiController]
[Area("Notification")]
[Route("v1/customer")]
[ErrorMap(typeof(NotificationErrorMap))]
public sealed class CustomerNotificationsController(IMediator mediator) : ControllerBase
{
    private const string App = NotificationApp.Customer;

    /// <summary>List the caller's notifications.</summary>
    [HttpGet("notifications")]
    [AllUserType(Permission = "notification:read:own")]
    public Task<NotificationListView> List([FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListNotifications(HttpContext.Caller().AccountId, App, cursor, limit), HttpContext.RequestAborted);

    /// <summary>Mark every notification read.</summary>
    [HttpPost("notifications/read-all")]
    [AllUserType(Permission = "notification:read:own")]
    public async Task<IActionResult> ReadAll()
    {
        await mediator.Send(new MarkAllNotificationsRead(HttpContext.Caller().AccountId, App), HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>Mark one notification read.</summary>
    [HttpPost("notifications/{notificationId}/read")]
    [AllUserType(Permission = "notification:read:own")]
    public async Task<IActionResult> Read(Guid notificationId)
    {
        await mediator.Send(new MarkNotificationRead(HttpContext.Caller().AccountId, App, notificationId), HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>Register the device's push token.</summary>
    [HttpPut("device-token")]
    [AllUserType(Permission = "device:register")]
    public async Task<IActionResult> Device([FromBody] DeviceTokenInput body)
    {
        await mediator.Send(new RegisterDevice(HttpContext.Caller().AccountId, App, body), HttpContext.RequestAborted);
        return NoContent();
    }
}

/// <summary>The partner app's inbox and device (P-12).</summary>
[ApiController]
[Area("Notification")]
[Route("v1/provider")]
[ErrorMap(typeof(NotificationErrorMap))]
public sealed class MerchantNotificationsController(IMediator mediator) : ControllerBase
{
    private const string App = NotificationApp.Partner;

    /// <summary>List the caller's notifications.</summary>
    [HttpGet("notifications")]
    [AllUserType(Permission = "notification:read:own")]
    public Task<NotificationListView> List([FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListNotifications(HttpContext.Caller().AccountId, App, cursor, limit), HttpContext.RequestAborted);

    /// <summary>Mark every notification read.</summary>
    [HttpPost("notifications/read-all")]
    [AllUserType(Permission = "notification:read:own")]
    public async Task<IActionResult> ReadAll()
    {
        await mediator.Send(new MarkAllNotificationsRead(HttpContext.Caller().AccountId, App), HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>Mark one notification read.</summary>
    [HttpPost("notifications/{notificationId}/read")]
    [AllUserType(Permission = "notification:read:own")]
    public async Task<IActionResult> Read(Guid notificationId)
    {
        await mediator.Send(new MarkNotificationRead(HttpContext.Caller().AccountId, App, notificationId), HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>Register the device's push token.</summary>
    [HttpPut("device-token")]
    [AllUserType(Permission = "device:register")]
    public async Task<IActionResult> Device([FromBody] DeviceTokenInput body)
    {
        await mediator.Send(new RegisterDevice(HttpContext.Caller().AccountId, App, body), HttpContext.RequestAborted);
        return NoContent();
    }
}
