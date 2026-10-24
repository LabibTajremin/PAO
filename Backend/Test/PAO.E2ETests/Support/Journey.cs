namespace PAO.E2ETests.Support;

/// <summary>
/// Base of every black-box journey. Journeys share one stack and its seeded admins, so they
/// run one at a time (the "stack" collection) and are filtered out of the start-up smoke run
/// by their trait. Cleanups registered during a test run when it ends, pass or fail, newest
/// first, as Go's t.Cleanup does.
/// </summary>
[Collection("stack")]
[Trait("Category", "Journey")]
public abstract class Journey : IAsyncLifetime
{
    private static readonly List<Func<Task>> Pending = [];

    /// <summary>Runs `cleanup` when the current test ends.</summary>
    public static void OnCleanup(Func<Task> cleanup) => Pending.Add(cleanup);

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async ValueTask DisposeAsync()
    {
        var errors = new List<Exception>();
        while (Pending.Count > 0)
        {
            var cleanup = Pending[^1];
            Pending.RemoveAt(Pending.Count - 1);
            try
            {
                await cleanup();
            }
            catch (Exception err) when (err is InvalidOperationException or HttpRequestException or TimeoutException)
            {
                errors.Add(err);
            }
        }
        GC.SuppressFinalize(this);
        if (errors.Count > 0)
        {
            throw new AggregateException("cleanup failed", errors);
        }
    }
}

/// <summary>The journeys' collection: never run in parallel with each other.</summary>
[CollectionDefinition("stack", DisableParallelization = true)]
public sealed class StackCollection;
