using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Appearance.Commands;

/// <summary>Replaces a slot's image with an admin's upload (ADR-0040).</summary>
public sealed record UploadArtwork(string Key, ArtworkUpload Input, Guid ActorId) : ICommand<ArtworkSlotView>;

/// <summary>Puts a slot's seed image back.</summary>
public sealed record ResetArtwork(string Key, Guid ActorId) : ICommand<ArtworkSlotView>;

/// <summary>Checks, stores and records the upload.</summary>
public sealed class UploadArtworkHandler(ArtworkStore files, ArtworkRepository repository, IClock clock, IMapper mapper)
    : IRequestHandler<UploadArtwork, ArtworkSlotView>
{
    /// <inheritdoc />
    public async Task<ArtworkSlotView> Handle(UploadArtwork request, CancellationToken cancellationToken)
    {
        var slot = ArtworkSlots.Find(request.Key) ?? throw new DomainException(AdminReasons.ArtworkSlotNotFound);
        var buffer = new byte[request.Input.Data.Length];
        if (!Convert.TryFromBase64String(request.Input.Data, buffer, out var length))
        {
            throw new DomainException(AdminReasons.ArtworkUnreadable);
        }
        var file = ArtworkStore.Checked(slot, request.Input.ContentType, buffer[..length]);
        var url = await files.Put(slot.Key, request.Input.ContentType, file, cancellationToken);
        var current = await repository.Find(slot.Key, cancellationToken);
        var record = new ArtworkRecord
        {
            Key = slot.Key,
            Url = url,
            ContentType = request.Input.ContentType,
            SeedUrl = current?.SeedUrl,
            Version = (current?.Version ?? 0) + 1,
            Replaced = true,
            UpdatedAt = clock.Now,
            UpdatedBy = request.ActorId,
        };
        await repository.Save(record, new ArtworkChanged { Key = slot.Key, Url = url, Reset = false, ActorId = request.ActorId }, cancellationToken);
        return mapper.Map<(ArtworkSpec, ArtworkRecord?), ArtworkSlotView>((slot, record));
    }
}

/// <summary>Points the slot at its seed image, or at the app's bundled one before seeding.</summary>
public sealed class ResetArtworkHandler(ArtworkRepository repository, IClock clock, IMapper mapper)
    : IRequestHandler<ResetArtwork, ArtworkSlotView>
{
    /// <inheritdoc />
    public async Task<ArtworkSlotView> Handle(ResetArtwork request, CancellationToken cancellationToken)
    {
        var slot = ArtworkSlots.Find(request.Key) ?? throw new DomainException(AdminReasons.ArtworkSlotNotFound);
        var current = await repository.Find(slot.Key, cancellationToken);
        var seed = current?.SeedUrl;
        var record = new ArtworkRecord
        {
            Key = slot.Key,
            Url = seed,
            ContentType = seed is null ? null : ArtworkFiles.Svg,
            SeedUrl = seed,
            Version = (current?.Version ?? 0) + 1,
            Replaced = false,
            UpdatedAt = clock.Now,
            UpdatedBy = request.ActorId,
        };
        await repository.Save(record, new ArtworkChanged { Key = slot.Key, Url = seed ?? string.Empty, Reset = true, ActorId = request.ActorId }, cancellationToken);
        return mapper.Map<(ArtworkSpec, ArtworkRecord?), ArtworkSlotView>((slot, record));
    }
}
