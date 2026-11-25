using PAO.Core.Areas.Customer.Repositories;
using PAO.Core.Areas.Customer.Services;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Customer.Features.Places.Queries;

/// <summary>Places matching <paramref name="Query"/>, nearest to <paramref name="Near"/> among equals (ADR-0042).</summary>
public sealed record SearchPlaces(string Query, GeoPoint? Near, string Language) : IQuery<PlaceListView>;

/// <summary>The place at <paramref name="Point"/>, inside the launch area only.</summary>
public sealed record ReversePlace(GeoPoint Point, string Language) : IQuery<PlaceView>;

/// <summary>Answers the place lookups from Postgres, through a one-day Redis cache.</summary>
public sealed class PlaceQueriesHandler(PlaceRepository places, CustomerPeers peers, PlaceCache cache)
    : IRequestHandler<SearchPlaces, PlaceListView>, IRequestHandler<ReversePlace, PlaceView>
{
    /// <summary>The most places one search returns.</summary>
    public const int Limit = 10;

    /// <inheritdoc />
    public async Task<PlaceListView> Handle(SearchPlaces request, CancellationToken cancellationToken)
    {
        var q = PlaceText.Normalise(request.Query);
        if (q.Length is < 2 or > 80)
        {
            throw new DomainException(CustomerReasons.Invalid);
        }
        // Points are rounded to about a kilometre, so nearby customers share the cache.
        var near = request.Near is { } p ? $"{Math.Round(p.Lat, 2)},{Math.Round(p.Lng, 2)}" : "-";
        return await cache.GetOrAdd(["search", request.Language, near, q], async () =>
            new PlaceListView([.. (await places.Search(q, request.Near, Limit, cancellationToken)).Select(r => View(r, request.Language))]));
    }

    /// <inheritdoc />
    public async Task<PlaceView> Handle(ReversePlace request, CancellationToken cancellationToken)
    {
        if (!LaunchArea.Covers(await peers.LaunchAreaGeoJson(cancellationToken), request.Point))
        {
            throw new DomainException(CustomerReasons.OutsideLaunchArea);
        }
        var key = $"{Math.Round(request.Point.Lat, 4)},{Math.Round(request.Point.Lng, 4)}";
        var found = await cache.GetOrAdd(["reverse", request.Language, key], async () =>
            await places.Nearest(request.Point, cancellationToken) is { } row ? new PlaceListView([View(row, request.Language)]) : new PlaceListView([]));
        return found.Items.Count == 0 ? throw new DomainException(CustomerReasons.PlaceNotFound) : found.Items[0];
    }

    /// <summary>A place in <paramref name="language"/>, falling back to the other name.</summary>
    public static PlaceView View(PlaceRow r, string language) => new()
    {
        Id = r.Id,
        Kind = r.Kind,
        Title = language == "bn" && r.NameBn.Length > 0 ? r.NameBn : r.NameEn,
        Area = r.Area.Length == 0 ? null : r.Area,
        Location = r.Point,
    };
}

/// <summary>The place answers in Redis for a day; a cache outage reads as a miss.</summary>
public sealed class PlaceCache(JsonCache cache, RedisKeys keys, ILogger<PlaceCache> logger)
{
    private static readonly TimeSpan Ttl = TimeSpan.FromDays(1);

    /// <summary>The cached answer for <paramref name="parts"/>, or <paramref name="load"/>'s, stored for next time.</summary>
    public async Task<PlaceListView> GetOrAdd(string[] parts, Func<Task<PlaceListView>> load)
    {
        var key = keys.Key(["cache", "places", .. parts]);
        try
        {
            if (await cache.Get<PlaceListView>(key) is { } hit)
            {
                return hit;
            }
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "places cache read failed");
        }
        var value = await load();
        try
        {
            await cache.Set(key, value, Ttl);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "places cache write failed");
        }
        return value;
    }
}
