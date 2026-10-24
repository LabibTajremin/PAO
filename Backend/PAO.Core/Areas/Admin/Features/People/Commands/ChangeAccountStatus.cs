using FluentValidation;
using PAO.Core.Areas.Admin.Services;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.People.Commands;

/// <summary>Suspends, bans or reinstates a provider (A-05); the answer shows the decision before the read model catches up.</summary>
public sealed record ChangeProviderStatus(StatusChange Change) : ICommand<AdminProviderDetailView>;

/// <summary>Suspends, bans or reinstates a customer (A-05).</summary>
public sealed record ChangeCustomerStatus(StatusChange Change) : ICommand<AdminCustomerDetailView>;

/// <summary>Checks <see cref="ChangeProviderStatus"/>.</summary>
public sealed class ChangeProviderStatusValidator : AbstractValidator<ChangeProviderStatus>
{
    /// <summary>The spec lists the statuses.</summary>
    public ChangeProviderStatusValidator() => RuleFor(r => r.Change.Status).NotEmpty();
}

/// <summary>Checks <see cref="ChangeCustomerStatus"/>.</summary>
public sealed class ChangeCustomerStatusValidator : AbstractValidator<ChangeCustomerStatus>
{
    /// <summary>The spec lists the statuses.</summary>
    public ChangeCustomerStatusValidator() => RuleFor(r => r.Change.Status).NotEmpty();
}

/// <summary>Answers <see cref="ChangeProviderStatus"/>; an active provider without Level 1 shows as pending.</summary>
public sealed class ChangeProviderStatusHandler(AdminConsole console) : IRequestHandler<ChangeProviderStatus, AdminProviderDetailView>
{
    /// <inheritdoc />
    public async Task<AdminProviderDetailView> Handle(ChangeProviderStatus request, CancellationToken cancellationToken)
    {
        var record = await console.ProviderRecord(request.Change.AccountId, cancellationToken);
        await console.SetStatus(request.Change, cancellationToken);
        var pending = request.Change.Status == AccountStatus.Active && record.Level == 0;
        return await console.Provider(request.Change.AccountId, pending ? AccountStatus.Pending : request.Change.Status, cancellationToken);
    }
}

/// <summary>Answers <see cref="ChangeCustomerStatus"/>.</summary>
public sealed class ChangeCustomerStatusHandler(AdminConsole console) : IRequestHandler<ChangeCustomerStatus, AdminCustomerDetailView>
{
    /// <inheritdoc />
    public async Task<AdminCustomerDetailView> Handle(ChangeCustomerStatus request, CancellationToken cancellationToken)
    {
        await console.CustomerRecord(request.Change.AccountId, cancellationToken);
        await console.SetStatus(request.Change, cancellationToken);
        return await console.Customer(request.Change.AccountId, request.Change.Status, cancellationToken);
    }
}
