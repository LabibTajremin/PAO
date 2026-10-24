using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Events.Commands;

/// <summary>`provider.EnrolmentStepSaved`: puts the matching profile item back into review.</summary>
public sealed record ApplyStepSaved(Guid Merchant, string Step) : ICommand;

/// <summary>`identity.AccountStatusChanged`: blocks or unblocks; a ban also blocks the NID.</summary>
public sealed record ApplyAccountStatus(Guid Account, string Status) : ICommand;

/// <summary>`identity.AccountDeleted`: starts the document retention clock (ADR-0023).</summary>
public sealed record RecordAccountClosure(Guid Account) : ICommand;

/// <summary>Answers <see cref="ApplyStepSaved"/>.</summary>
public sealed class ApplyStepSavedHandler(MerchantStatus status) : IRequestHandler<ApplyStepSaved, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(ApplyStepSaved request, CancellationToken cancellationToken)
    {
        await status.StepSaved(request.Merchant, request.Step, cancellationToken);
        return Unit.Value;
    }
}

/// <summary>Answers <see cref="ApplyAccountStatus"/>.</summary>
public sealed class ApplyAccountStatusHandler(DocumentLifecycle lifecycle) : IRequestHandler<ApplyAccountStatus, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(ApplyAccountStatus request, CancellationToken cancellationToken)
    {
        await lifecycle.AccountStatusChanged(request.Account, request.Status, cancellationToken);
        return Unit.Value;
    }
}

/// <summary>Answers <see cref="RecordAccountClosure"/>.</summary>
public sealed class RecordAccountClosureHandler(DocumentLifecycle lifecycle) : IRequestHandler<RecordAccountClosure, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(RecordAccountClosure request, CancellationToken cancellationToken)
    {
        await lifecycle.Closed(request.Account, cancellationToken);
        return Unit.Value;
    }
}
