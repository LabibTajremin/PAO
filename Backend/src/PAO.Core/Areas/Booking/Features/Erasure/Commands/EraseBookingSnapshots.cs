using FluentValidation;
using PAO.Core.Areas.Booking.Repositories;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Erasure.Commands;

/// <summary>Blanks a deleted account's personal details in the booking snapshots (PRD §11); the account may have booked, served, or both.</summary>
public sealed record EraseBookingSnapshots(Guid AccountId) : ICommand;

/// <summary>Checks <see cref="EraseBookingSnapshots"/>.</summary>
public sealed class EraseBookingSnapshotsValidator : AbstractValidator<EraseBookingSnapshots>
{
    /// <summary>An event without an account id erases nothing.</summary>
    public EraseBookingSnapshotsValidator() => RuleFor(r => r.AccountId).NotNull();
}

/// <summary>Answers <see cref="EraseBookingSnapshots"/>; both updates are idempotent, so a redelivered event is harmless.</summary>
public sealed class EraseBookingSnapshotsHandler(BookingRepository repository) : IRequestHandler<EraseBookingSnapshots, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(EraseBookingSnapshots request, CancellationToken cancellationToken)
    {
        await repository.Erase(request.AccountId, cancellationToken);
        return Unit.Value;
    }
}
