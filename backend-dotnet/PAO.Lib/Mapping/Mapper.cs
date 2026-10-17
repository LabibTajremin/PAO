namespace PAO.Lib.Mapping;

/// <summary>
/// Converts between db models, DTOs and view models with hand-written maps registered by
/// mapping profiles. No reflection: a missing map fails loudly instead of copying
/// whatever names happen to match.
/// </summary>
public interface IMapper
{
    /// <summary>Maps one value with the registered map from TSource to TDestination.</summary>
    TDestination Map<TSource, TDestination>(TSource source);

    /// <summary>Maps every value of `sources`, keeping their order.</summary>
    IReadOnlyList<TDestination> MapAll<TSource, TDestination>(IEnumerable<TSource> sources);
}

/// <summary>Registers one area's maps, e.g. `AccountProfile` for the Identity area.</summary>
public interface IMappingProfile
{
    /// <summary>Adds this profile's maps to `registry`.</summary>
    void Configure(MappingRegistry registry);
}

/// <summary>The maps of every profile, keyed by source and destination type.</summary>
public sealed class MappingRegistry
{
    private readonly Dictionary<(Type Source, Type Destination), Delegate> maps = [];

    /// <summary>Registers the map from TSource to TDestination; a second map for the pair throws.</summary>
    public MappingRegistry Add<TSource, TDestination>(Func<TSource, IMapper, TDestination> map)
    {
        if (!maps.TryAdd((typeof(TSource), typeof(TDestination)), map))
        {
            throw new InvalidOperationException(
                $"a map from {typeof(TSource).Name} to {typeof(TDestination).Name} is already registered");
        }
        return this;
    }

    internal Func<TSource, IMapper, TDestination> Find<TSource, TDestination>() =>
        maps.TryGetValue((typeof(TSource), typeof(TDestination)), out var map)
            ? (Func<TSource, IMapper, TDestination>)map
            : throw new InvalidOperationException(
                $"no map from {typeof(TSource).Name} to {typeof(TDestination).Name}; add one to a mapping profile");
}

/// <summary>The <see cref="IMapper"/> over the maps of the given profiles.</summary>
public sealed class Mapper : IMapper
{
    private readonly MappingRegistry registry = new();

    /// <summary>Builds the mapper from every registered profile.</summary>
    public Mapper(IEnumerable<IMappingProfile> profiles)
    {
        foreach (var profile in profiles)
        {
            profile.Configure(registry);
        }
    }

    /// <inheritdoc />
    public TDestination Map<TSource, TDestination>(TSource source) =>
        registry.Find<TSource, TDestination>()(source, this);

    /// <inheritdoc />
    public IReadOnlyList<TDestination> MapAll<TSource, TDestination>(IEnumerable<TSource> sources)
    {
        var map = registry.Find<TSource, TDestination>();
        return [.. sources.Select(s => map(s, this))];
    }
}
