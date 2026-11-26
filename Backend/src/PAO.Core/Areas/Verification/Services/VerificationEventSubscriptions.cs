using PAO.Core.Areas.Verification.Features.Events.Commands;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>
/// Re-reviews changed profile steps, blocks suspended or banned merchants and starts the
/// retention clock of deleted accounts. Each handler converges on the same state when an
/// event is delivered twice.
/// </summary>
public sealed class VerificationEventSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        bus.Subscribe(MerchantEvents.EnrolmentStepSaved, "verification", (envelope, cancellationToken) =>
        {
            var p = new EventPayload(envelope);
            return Send(new ApplyStepSaved(Guid.Parse(p.Id("providerId")), p.Text("step")), cancellationToken);
        });
        bus.Subscribe(IdentityEvents.AccountStatusChanged, "verification", (envelope, cancellationToken) =>
        {
            var p = new EventPayload(envelope);
            return Send(new ApplyAccountStatus(Guid.Parse(p.Id("accountId")), p.Text("to")), cancellationToken);
        });
        bus.Subscribe(IdentityEvents.AccountDeleted, "verification", (envelope, cancellationToken) =>
            Send(new RecordAccountClosure(Guid.Parse(new EventPayload(envelope).Id("accountId"))), cancellationToken));
    }

    private async Task Send<T>(IRequest<T> request, CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(request, cancellationToken);
    }
}

/// <summary>Runs the expiry sweep at a chosen time for the `/__test/verification/expire` hook.</summary>
public sealed class DocumentExpiryHook(IMediator mediator) : IDocumentExpiry
{
    /// <inheritdoc />
    public Task ExpireDocumentsAt(DateTimeOffset at, CancellationToken cancellationToken) => mediator.Send(new ExpireDocuments(at), cancellationToken);
}
