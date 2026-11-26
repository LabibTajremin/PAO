using PAO.Core.Areas.Customer.Repositories;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Places.Commands;

/// <summary>
/// Replaces every place with the features of a GeoJSON-sequence file (ADR-0042 §2); lines
/// without a usable name or point are skipped. The repository writes in its own transaction.
/// Returns how many places were stored. `KeepExisting` leaves a non-empty table alone, so the
/// dev seed never overwrites a real import.
/// </summary>
public sealed record ImportPlaces(IEnumerable<string> Lines, bool KeepExisting = false) : IRequest<int>;

/// <summary>Answers <see cref="ImportPlaces"/>.</summary>
public sealed class ImportPlacesHandler(PlaceRepository places) : IRequestHandler<ImportPlaces, int>
{
    /// <inheritdoc />
    public async Task<int> Handle(ImportPlaces request, CancellationToken cancellationToken)
    {
        if (request.KeepExisting && await places.Any(cancellationToken))
        {
            return 0;
        }
        return await places.Replace(request.Lines.Where(l => !string.IsNullOrWhiteSpace(l)).Select(PlaceFeatures.Parse).OfType<PlaceRow>(), cancellationToken);
    }
}
