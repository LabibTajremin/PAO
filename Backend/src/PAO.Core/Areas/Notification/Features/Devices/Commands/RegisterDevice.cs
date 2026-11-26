using PAO.Core.Areas.Notification.Repositories;
using PAO.EF.Notification;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Notification.Features.Devices.Commands;

/// <summary>Registers a push token for the account in an app; the token moves to whoever registered it last.</summary>
public sealed record RegisterDevice(Guid Account, string App, DeviceTokenInput Device) : ICommand;

/// <summary>Answers <see cref="RegisterDevice"/>.</summary>
public sealed class RegisterDeviceHandler(NotificationRepository repository, IClock clock) : IRequestHandler<RegisterDevice, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(RegisterDevice request, CancellationToken cancellationToken)
    {
        await repository.SaveDevice(new DeviceTokenRecord
        {
            Token = request.Device.Token,
            AccountId = request.Account,
            App = request.App,
            Platform = request.Device.Platform,
            UpdatedAt = clock.Now,
        }, cancellationToken);
        return Unit.Value;
    }
}
