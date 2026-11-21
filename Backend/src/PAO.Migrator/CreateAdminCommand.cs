using System.Collections;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Mediator;

namespace PAO.Migrator;

/// <summary>
/// `migrate create-admin --email E --name N`: creates the first super admin in any
/// environment, production included. The password comes from ADMIN_PASSWORD, never from
/// argv, so it stays out of shell history and process listings. An existing email is left
/// untouched, which makes the command safe to repeat in a release script.
/// </summary>
public static class CreateAdminCommand
{
    /// <summary>The variable holding the new admin's password.</summary>
    public const string PasswordVariable = "ADMIN_PASSWORD";

    /// <summary>Reads `--email E --name N` (either order) from `args`; null when malformed.</summary>
    public static (string Email, string Name)? ParseArguments(IReadOnlyList<string> args)
    {
        string? email = null, name = null;
        if (args.Count != 4)
        {
            return null;
        }
        for (var i = 0; i < args.Count; i += 2)
        {
            switch (args[i])
            {
                case "--email": email = args[i + 1]; break;
                case "--name": name = args[i + 1]; break;
                default: return null;
            }
        }
        return email is not null && name is not null ? (email, name) : null;
    }

    /// <summary>Runs `create-admin` with its arguments `args`; malformed arguments print the usage and return 2.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, string[] args, TextWriter output)
    {
        if (ParseArguments(args) is not { } parsed)
        {
            await output.WriteLineAsync(MigratorCommand.Usage);
            return 2;
        }
        return await Run(paths, environment, parsed.Email, parsed.Name, output);
    }

    /// <summary>Creates the admin with the configuration of `environment`; returns the exit code.</summary>
    public static async Task<int> Run(PaoPaths paths, IDictionary environment, string email, string name, TextWriter output)
    {
        if (environment[PasswordVariable] is not string { Length: > 0 } password)
        {
            await output.WriteLineAsync($"migrate create-admin: {PasswordVariable} is required");
            return 1;
        }
        using var host = SeedCommand.BuildHost(paths, environment);
        await using var scope = host.Services.CreateAsyncScope();
        try
        {
            var created = await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new CreateSuperAdminCommand(email, name, password));
            await output.WriteLineAsync(created
                ? $"migrate create-admin: created super admin {email}; TOTP enrolment happens at the first login"
                : $"migrate create-admin: {email} already exists; nothing changed");
            return 0;
        }
        catch (ApiError error) when (error.Details is { } details)
        {
            await output.WriteLineAsync($"migrate create-admin: {details["field"]} {details["reason"]}");
            return 1;
        }
    }
}
