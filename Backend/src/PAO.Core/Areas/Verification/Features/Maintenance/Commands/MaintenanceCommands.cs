using PAO.Core.Areas.Verification.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Maintenance.Commands;

/// <summary>Answers <see cref="ExpireDocuments"/> for the `verification.expire_documents` job and the test hook.</summary>
public sealed class ExpireDocumentsHandler(DocumentLifecycle lifecycle, IClock clock) : IRequestHandler<ExpireDocuments, int>
{
    /// <inheritdoc />
    public Task<int> Handle(ExpireDocuments request, CancellationToken cancellationToken) =>
        lifecycle.Expire(request.At ?? clock.Now, cancellationToken);
}

/// <summary>Answers <see cref="RemindExpiringDocuments"/> for the `verification.expiry_reminders` job.</summary>
public sealed class RemindExpiringDocumentsHandler(DocumentLifecycle lifecycle) : IRequestHandler<RemindExpiringDocuments, int>
{
    /// <inheritdoc />
    public Task<int> Handle(RemindExpiringDocuments request, CancellationToken cancellationToken) => lifecycle.Remind(cancellationToken);
}

/// <summary>Answers <see cref="PurgeClosedAccounts"/> for the `verification.purge_closed` job.</summary>
public sealed class PurgeClosedAccountsHandler(DocumentLifecycle lifecycle) : IRequestHandler<PurgeClosedAccounts, int>
{
    /// <inheritdoc />
    public Task<int> Handle(PurgeClosedAccounts request, CancellationToken cancellationToken) => lifecycle.PurgeExpired(cancellationToken);
}
