using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Settings.Commands;

/// <summary>Changes one setting (A-10); `SettingChanged` feeds the audit trail and the cache is dropped so readers see the change at once.</summary>
public sealed record UpdateSetting(Guid ActorId, string Key, string Value) : ICommand<SettingView>;

/// <summary>Checks <see cref="UpdateSetting"/>.</summary>
public sealed class UpdateSettingValidator : AbstractValidator<UpdateSetting>
{
    /// <summary>A key; the type check needs the stored setting.</summary>
    public UpdateSettingValidator() => RuleFor(r => r.Key).NotEmpty();
}

/// <summary>Answers <see cref="UpdateSetting"/>.</summary>
public sealed class UpdateSettingHandler(SettingsRepository repository, SettingValues values, IClock clock, IMapper mapper) : IRequestHandler<UpdateSetting, SettingView>
{
    /// <inheritdoc />
    public async Task<SettingView> Handle(UpdateSetting request, CancellationToken cancellationToken)
    {
        var current = await repository.Get(request.Key, cancellationToken);
        if (!AdminRules.FitsType(current.Type, request.Value))
        {
            throw new DomainException(AdminReasons.SettingInvalid);
        }
        var updated = new SettingRecord
        {
            Key = current.Key,
            Value = request.Value,
            Type = current.Type,
            Description = current.Description,
            UpdatedAt = clock.Now,
            UpdatedBy = request.ActorId,
        };
        await repository.Update(updated, new SettingChanged { Key = request.Key, Before = current.Value, After = request.Value, ActorId = request.ActorId }, cancellationToken);
        await values.Invalidate();
        return mapper.Map<SettingRecord, SettingView>(updated);
    }
}
