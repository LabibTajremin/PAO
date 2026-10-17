using System.Text;
using Microsoft.EntityFrameworkCore;

namespace PAO.EF.Conventions;

/// <summary>
/// Maps PascalCase properties to the snake_case columns the SQL scripts use, so entity
/// configurations only name tables and keys.
/// </summary>
public static class SnakeCaseNames
{
    /// <summary>Converts `ScreenId` to `screen_id` and `HTTPStatus` to `http_status`.</summary>
    public static string ToSnakeCase(string name)
    {
        var builder = new StringBuilder(name.Length + 8);
        for (var i = 0; i < name.Length; i++)
        {
            var c = name[i];
            if (char.IsUpper(c) && i > 0 && StartsWord(name, i))
            {
                builder.Append('_');
            }
            builder.Append(char.ToLowerInvariant(c));
        }
        return builder.ToString();
    }

    /// <summary>Gives every property without an explicit column name its snake_case name.</summary>
    public static void Apply(ModelBuilder modelBuilder)
    {
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entity.GetProperties())
            {
                property.SetColumnName(ToSnakeCase(property.Name));
            }
        }
    }

    // A capital starts a word after a lower-case letter or digit, or before one in an acronym.
    private static bool StartsWord(string name, int i)
    {
        var previous = name[i - 1];
        if (char.IsLower(previous) || char.IsDigit(previous))
        {
            return true;
        }
        return i + 1 < name.Length && char.IsLower(name[i + 1]);
    }
}
