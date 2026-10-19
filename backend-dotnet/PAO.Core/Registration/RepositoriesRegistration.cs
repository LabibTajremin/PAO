using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Audit.Repositories;
using PAO.Core.Areas.Booking.Repositories;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Customer.Repositories;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Core.Areas.Media.Repositories;
using PAO.Core.Areas.Rating.Repositories;
using PAO.Core.Areas.Merchant.Repositories;
using PAO.Core.Areas.Notification.Repositories;
using PAO.Core.Areas.Verification.Repositories;

namespace PAO.Core.Registration;

/// <summary>The repositories of every area (repository pattern over EF Core, ADR-0034).</summary>
public static class RepositoriesRegistration
{
    /// <summary>Adds the repositories; each area's are added here as its use cases are ported (P17 tasks 2–5).</summary>
    public static IServiceCollection AddRepositories(this IServiceCollection services) => services
        .AddScoped<BookingRepository>()
        .AddScoped<BookingQueries>()
        .AddScoped<RatingRepository>()
        .AddScoped<SettingsRepository>()
        .AddScoped<ComplaintRepository>()
        .AddScoped<DashboardRepository>()
        .AddScoped<CatalogRepository>()
        .AddScoped<CatalogWriteRepository>()
        .AddScoped<CustomerRepository>()
        .AddScoped<AddressRepository>()
        .AddScoped<MerchantRepository>()
        .AddSingleton<IPresence, RedisPresence>()
        .AddScoped<MediaRepository>()
        .AddScoped<NotificationRepository>()
        .AddScoped<IIdentityRepository, IdentityRepository>()
        .AddSingleton<ICodeStore, RedisCodeStore>()
        .AddSingleton<ISendThrottle, RedisSendThrottle>()
        .AddSingleton<ISessionStore, RedisSessionStore>()
        .AddSingleton<IChallengeStore, RedisChallengeStore>()
        .AddScoped<IAuditRepository, AuditRepository>()
        .AddScoped<VerificationStateRepository>()
        .AddScoped<VerificationRepository>()
        .AddScoped<ClosedAccountRepository>();
}
