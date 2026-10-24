using FluentValidation;
using PAO.Core.Areas.Admin.Repositories;
using PAO.EF.Admin;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Settings.Queries;

/// <summary>Every setting with its type and description, from the database (A-10).</summary>
public sealed record ListSettings : IQuery<SettingListView>;

/// <summary>Checks <see cref="ListSettings"/>.</summary>
public sealed class ListSettingsValidator : AbstractValidator<ListSettings>
{
    /// <summary>Nothing to check.</summary>
    public ListSettingsValidator() => RuleFor(r => r).NotNull();
}

/// <summary>Answers <see cref="ListSettings"/>.</summary>
public sealed class ListSettingsHandler(SettingsRepository repository, IMapper mapper) : IRequestHandler<ListSettings, SettingListView>
{
    /// <inheritdoc />
    public async Task<SettingListView> Handle(ListSettings request, CancellationToken cancellationToken) =>
        new() { Items = mapper.MapAll<SettingRecord, SettingView>(await repository.List(cancellationToken)) };
}
