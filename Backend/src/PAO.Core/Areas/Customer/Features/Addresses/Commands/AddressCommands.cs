using FluentValidation;
using PAO.Core.Areas.Customer.Repositories;
using PAO.Core.Areas.Customer.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Addresses.Commands;

/// <summary>Saves a new address, up to <see cref="CustomerRules.MaxAddresses"/> (C-02).</summary>
public sealed record AddAddress(Guid CustomerId, AddressInput Input) : ICommand<AddressView>;

/// <summary>Edits a saved address.</summary>
public sealed record UpdateAddress(Guid CustomerId, Guid AddressId, AddressInput Input) : ICommand<AddressView>;

/// <summary>Makes a saved address the default.</summary>
public sealed record SetDefaultAddress(Guid CustomerId, Guid AddressId) : ICommand<AddressView>;

/// <summary>Removes a saved address.</summary>
public sealed record DeleteAddress(Guid CustomerId, Guid AddressId) : ICommand;

/// <summary>
/// The address rules, with the domain reasons the error map knows (VALIDATION_FAILED,
/// OUTSIDE_SERVICE_AREA), before the transaction opens.
/// </summary>
public static class AddressRules
{
    /// <summary>Throws the reason `input` breaks, if any.</summary>
    public static void Check(AddressInput input) =>
        CustomerRules.Check(CustomerRules.AddressProblem(input.Label, input.Line1, input.Line2 ?? string.Empty, input.Area ?? string.Empty, input.Location));

    /// <summary>The address `input` describes.</summary>
    public static SavedAddress ToAddress(Guid id, Guid customerId, AddressInput input, DateTimeOffset at) => new()
    {
        Id = id,
        CustomerId = customerId,
        Label = input.Label,
        Line1 = input.Line1,
        Line2 = input.Line2 ?? string.Empty,
        Area = input.Area ?? string.Empty,
        Location = input.Location,
        IsDefault = input.IsDefault == true,
        CreatedAt = at,
    };
}

/// <summary>Checks <see cref="AddAddress"/>.</summary>
public sealed class AddAddressValidator : AbstractValidator<AddAddress>
{
    /// <summary>Declares the rule.</summary>
    public AddAddressValidator() => RuleFor(r => r.Input).Custom((input, _) => AddressRules.Check(input));
}

/// <summary>Checks <see cref="UpdateAddress"/>.</summary>
public sealed class UpdateAddressValidator : AbstractValidator<UpdateAddress>
{
    /// <summary>Declares the rule.</summary>
    public UpdateAddressValidator() => RuleFor(r => r.Input).Custom((input, _) => AddressRules.Check(input));
}

/// <summary>Answers <see cref="AddAddress"/>; the first address becomes the default.</summary>
public sealed class AddAddressHandler(AddressRepository addresses, IIdGenerator ids, IClock clock, IMapper mapper) : IRequestHandler<AddAddress, AddressView>
{
    /// <inheritdoc />
    public async Task<AddressView> Handle(AddAddress request, CancellationToken cancellationToken)
    {
        var address = AddressRules.ToAddress(ids.NewId(), request.CustomerId, request.Input, clock.Now);
        return mapper.Map<SavedAddress, AddressView>(await addresses.Add(address, CustomerRules.MaxAddresses, cancellationToken));
    }
}

/// <summary>Answers <see cref="UpdateAddress"/>; turning the default off is done by picking another one.</summary>
public sealed class UpdateAddressHandler(AddressRepository addresses, IClock clock, IMapper mapper) : IRequestHandler<UpdateAddress, AddressView>
{
    /// <inheritdoc />
    public async Task<AddressView> Handle(UpdateAddress request, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        await addresses.Update(AddressRules.ToAddress(request.AddressId, request.CustomerId, request.Input, now), now, cancellationToken);
        return mapper.Map<SavedAddress, AddressView>(await addresses.Get(request.CustomerId, request.AddressId, cancellationToken));
    }
}

/// <summary>Answers <see cref="SetDefaultAddress"/>.</summary>
public sealed class SetDefaultAddressHandler(AddressRepository addresses, IMapper mapper) : IRequestHandler<SetDefaultAddress, AddressView>
{
    /// <inheritdoc />
    public async Task<AddressView> Handle(SetDefaultAddress request, CancellationToken cancellationToken)
    {
        await addresses.SetDefault(request.CustomerId, request.AddressId, cancellationToken);
        return mapper.Map<SavedAddress, AddressView>(await addresses.Get(request.CustomerId, request.AddressId, cancellationToken));
    }
}

/// <summary>Answers <see cref="DeleteAddress"/>; deleting the default promotes the newest one left.</summary>
public sealed class DeleteAddressHandler(AddressRepository addresses) : IRequestHandler<DeleteAddress, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(DeleteAddress request, CancellationToken cancellationToken)
    {
        await addresses.Delete(request.CustomerId, request.AddressId, cancellationToken);
        return Unit.Value;
    }
}
