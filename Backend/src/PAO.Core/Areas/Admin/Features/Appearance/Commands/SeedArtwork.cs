using System.Security.Cryptography;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Appearance.Commands;

/// <summary>
/// Uploads the seed illustrations (`database/seed/artwork/&lt;slot&gt;.svg`) and records them;
/// `migrate seed` runs it. Idempotent: a seed is stored under its content hash, and slots an
/// admin replaced keep their image. Returns how many slots have a seed file.
/// </summary>
public sealed record SeedArtwork(string Folder) : ICommand<int>;

/// <summary>Stores and records every seed file found.</summary>
public sealed class SeedArtworkHandler(ArtworkStore files, ArtworkRepository repository) : IRequestHandler<SeedArtwork, int>
{
    /// <inheritdoc />
    public async Task<int> Handle(SeedArtwork request, CancellationToken cancellationToken)
    {
        var seeded = 0;
        foreach (var slot in ArtworkSlots.All)
        {
            var path = Path.Combine(request.Folder, $"{slot.Key}.svg");
            if (!File.Exists(path))
            {
                continue;
            }
            var file = ArtworkStore.Checked(slot, ArtworkFiles.Svg, await File.ReadAllBytesAsync(path, cancellationToken));
            var name = $"seed-{Convert.ToHexStringLower(SHA256.HashData(file))[..16]}.svg";
            await repository.Seed(slot.Key, await files.PutAs(slot.Key, name, ArtworkFiles.Svg, file, cancellationToken), cancellationToken);
            seeded++;
        }
        return seeded;
    }
}
