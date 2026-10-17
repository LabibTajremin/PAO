using PAO.Gates;
using PAO.Infrastructure.Hosting;

namespace PAO.UnitTests.Architecture;

[Trait("Category", "Gate")]
public sealed class GateTests
{
    private static string Root => PaoPaths.Resolve(AppContext.BaseDirectory, null).Home;

    [Fact]
    public void Every_csharp_file_and_method_is_within_its_size_limit()
    {
        Assert.Empty(SizeChecker.Check(Root));
    }

    [Fact]
    public void Every_area_feature_controller_job_config_and_script_is_documented()
    {
        Assert.Empty(DocsChecker.Check(Root));
    }
}

public sealed class SizeCheckerTests
{
    private static string Lines(int n) => string.Concat(Enumerable.Repeat("// line\n", n));

    private static string Method(int bodyLines) => "class C\n{\n    void M()\n    {\n" + Lines(bodyLines) + "    }\n    int P { get { return 1; } }\n}\n";

    [Fact]
    public void Flags_long_files_with_the_test_allowance()
    {
        Assert.Single(SizeChecker.CheckFile("PAO.Core/A.cs", Lines(251)));
        Assert.Empty(SizeChecker.CheckFile("Test/PAO.UnitTests/A.cs", Lines(399)));
        Assert.Single(SizeChecker.CheckFile("Test/PAO.UnitTests/A.cs", Lines(401)));
    }

    [Fact]
    public void Flags_long_methods_constructors_and_local_functions()
    {
        Assert.Empty(SizeChecker.CheckFile("A.cs", Method(37)));
        Assert.Contains("M has 41 lines", Assert.Single(SizeChecker.CheckFile("A.cs", Method(38))), StringComparison.Ordinal);
        var ctor = "class C\n{\n    C()\n    {\n" + Lines(40) + "    }\n}\n";
        Assert.Contains("C has 43 lines", Assert.Single(SizeChecker.CheckFile("A.cs", ctor)), StringComparison.Ordinal);
        var local = "class C\n{\n    void M()\n    {\n        void L()\n        {\n" + Lines(40) + "        }\n    }\n}\n";
        Assert.Equal(2, SizeChecker.CheckFile("A.cs", local).Count());
        var accessor = "class C\n{\n    int P\n    {\n        get\n        {\n" + Lines(40) + "            return 1;\n        }\n    }\n}\n";
        Assert.Contains("GetAccessorDeclaration", Assert.Single(SizeChecker.CheckFile("A.cs", accessor)), StringComparison.Ordinal);
    }

    [Fact]
    public void Skips_build_output_and_generated_files()
    {
        var dir = Directory.CreateTempSubdirectory("pao-size").FullName;
        foreach (var sub in new[] { "bin", "obj", "src" })
        {
            Directory.CreateDirectory(Path.Combine(dir, sub));
        }
        File.WriteAllText(Path.Combine(dir, "bin", "Big.cs"), Lines(300));
        File.WriteAllText(Path.Combine(dir, "obj", "Big.cs"), Lines(300));
        File.WriteAllText(Path.Combine(dir, "src", "Big.g.cs"), Lines(300));
        File.WriteAllText(Path.Combine(dir, "src", "Big.cs"), Lines(300));
        Assert.Equal(["src/Big.cs: 300 lines (limit 250)"], SizeChecker.Check(dir));
        Directory.Delete(dir, recursive: true);
    }
}

public sealed class DocsCheckerTests : IDisposable
{
    private readonly string root = Directory.CreateTempSubdirectory("pao-docs").FullName;

    public void Dispose() => Directory.Delete(root, recursive: true);

    private void Write(string relative, string text)
    {
        var path = Path.Combine(root, relative);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path, text);
    }

    private void Tree()
    {
        Write("PAO.Core/Areas/Booking/Features/AcceptBooking/Commands/AcceptBookingHandler.cs", "class H {}");
        Write("PAO.Core/Areas/Booking/Controllers/JobsController.cs", "class JobsController {}");
        Write("PAO.Core/Areas/Booking/Services/Shared/IBookingSharedService.cs", "interface I {}");
        Write("PAO.Core/Areas/Booking/Repositories/BookingRepository.cs", "class R {}");
        Write("PAO.Core/Platform/UnimplementedController.cs", "class U {}");
        Write("PAO.BackgroundJobs/ExpireJob.cs", "public sealed class ExpireJob(int x) : IScheduledJob {}");
        Write("Config/http.json", """{"Http":{"Address":":8080"}}""");
        Write("DB Changes/booking/0001_init.sql", "-- +goose Up");
        Write("Test/Fake.cs", "class FakeJob : IScheduledJob {}");
    }

    private void Pages()
    {
        foreach (var page in DocsChecker.AreaPages)
        {
            Write($"Docs/Areas/Booking/{page}", "AcceptBooking JobsController IBookingSharedService BookingRepository");
        }
        Write("Docs/Api/README.md", "UnimplementedController [ops](../Operations/jobs.md) [web](https://pao.test) [top](#errors) [mail](mailto:a@b)");
        Write("Docs/Operations/jobs.md", "ExpireJob");
        Write("Docs/Config/README.md", "http.json Http");
        Write("Docs/Database/README.md", "booking/0001_init.sql");
    }

    [Fact]
    public void Passes_when_everything_has_its_entry()
    {
        Tree();
        Pages();
        Assert.Empty(DocsChecker.Check(root));
    }

    [Fact]
    public void Reports_every_missing_page_entry_and_broken_link()
    {
        Tree();
        Write("Docs/Areas/Booking/overview.md", "nothing");
        Write("Docs/Guide.md", "[gone](Missing.md) [area](Areas/Booking/overview.md)");
        var problems = DocsChecker.Check(root);
        Assert.Contains("Docs/Areas/Booking/features.md: missing page for area Booking", problems);
        Assert.Contains("Booking/features.md: no entry for feature AcceptBooking", problems);
        Assert.Contains("Booking/endpoints.md: no entry for controller JobsController", problems);
        Assert.Contains("Booking/overview.md: no entry for service IBookingSharedService", problems);
        Assert.Contains("Booking/data.md: no entry for repository BookingRepository", problems);
        Assert.Contains("Api/README.md: no entry for controller UnimplementedController", problems);
        Assert.Contains("Operations/jobs.md: no entry for job ExpireJob", problems);
        Assert.Contains("Config/README.md: no entry for config file or section http.json", problems);
        Assert.Contains("Config/README.md: no entry for config file or section Http", problems);
        Assert.Contains("Database/README.md: no entry for script booking/0001_init.sql", problems);
        Assert.Contains("Docs/Guide.md: broken link Missing.md", problems);
        Assert.DoesNotContain(problems, p => p.Contains("FakeJob", StringComparison.Ordinal));
    }

    [Fact]
    public void An_empty_tree_needs_no_pages()
    {
        Assert.Empty(DocsChecker.Check(root));
    }
}
