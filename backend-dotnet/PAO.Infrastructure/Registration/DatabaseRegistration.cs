using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Registration;

/// <summary>The database: the Npgsql data source (with PostGIS), the DbContext factory and the scoped context.</summary>
public static class DatabaseRegistration
{
    /// <summary>Adds the database for DATABASE_URL.</summary>
    public static IServiceCollection AddDatabase(this IServiceCollection services, PaoSettings settings) =>
        services.AddPaoDatabase(settings.Database.Url);
}
