using System.Reflection;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;
using PAO.Lib.Validation;

namespace PAO.Infrastructure.Mediation;

/// <summary>Registers the mediator, its pipeline, the handlers, validators and mapping profiles.</summary>
public static class MediatorSetup
{
    /// <summary>
    /// Scans `assemblies` for handlers, validators and mapping profiles, and PAO.Lib, where
    /// every area's profile lives, for profiles too. The pipeline order is logging →
    /// validation → transaction → handler.
    /// </summary>
    public static IServiceCollection AddMediator(this IServiceCollection services, params Assembly[] assemblies)
    {
        ValidationSetup.Configure();
        services.AddScoped<IMediator, Mediator>();
        services.AddScoped(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        services.AddScoped(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddScoped(typeof(IPipelineBehavior<,>), typeof(TransactionBehavior<,>));
        services.AddSingleton<IMapper, Mapper>();
        // Profiles live in PAO.Lib, which holds no handlers, so it is always scanned: an area
        // can no longer forget to register its profile by hand.
        var scanned = assemblies.Append(typeof(IMappingProfile).Assembly).Distinct();
        foreach (var type in scanned.SelectMany(a => a.GetTypes()).Where(t => t is { IsClass: true, IsAbstract: false }))
        {
            Register(services, type);
        }
        return services;
    }

    private static void Register(IServiceCollection services, Type type)
    {
        foreach (var contract in type.GetInterfaces().Where(i => i.IsGenericType))
        {
            var definition = contract.GetGenericTypeDefinition();
            if (definition == typeof(IRequestHandler<,>) || definition == typeof(IValidator<>))
            {
                services.AddScoped(contract, type);
            }
        }
        if (typeof(IMappingProfile).IsAssignableFrom(type))
        {
            services.TryAddEnumerable(ServiceDescriptor.Singleton(typeof(IMappingProfile), type));
        }
    }
}
