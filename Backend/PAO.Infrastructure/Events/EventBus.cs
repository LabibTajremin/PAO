using System.Text.Json;

namespace PAO.Infrastructure.Events;

/// <summary>A stored event as subscribers receive it.</summary>
public sealed record Envelope
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }

    /// <summary>The area schema whose outbox held the event.</summary>
    public required string Module { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The aggregate id.</summary>
    public required string AggregateId { get; init; }

    /// <summary>The payload as stored (JSON); read it with <see cref="EventPayload"/>.</summary>
    public required JsonElement Payload { get; init; }
    /// <summary>The occurred at.</summary>
    public required DateTimeOffset OccurredAt { get; init; }
}

/// <summary>Processes one event. Delivery is at least once, so handlers must be idempotent.</summary>
public delegate Task EventSubscriber(Envelope envelope, CancellationToken cancellationToken);

/// <summary>Delivers an event to its subscribers.</summary>
public interface IEventDispatcher
{
    /// <summary>Delivers `envelope`; throws when any subscriber failed.</summary>
    Task Dispatch(Envelope envelope, CancellationToken cancellationToken);
}

/// <summary>
/// Routes events to the subscribers areas register at start-up. It is in-process; the
/// interface lets a broker replace it later (PRD §9.3 rule 5).
/// </summary>
public sealed class EventBus : IEventDispatcher
{
    private readonly Dictionary<string, List<(string Name, EventSubscriber Handler)>> subscriptions = new(StringComparer.Ordinal);

    /// <summary>Registers `handler`, identified by `handlerName`, for events called `eventName`.</summary>
    public void Subscribe(string eventName, string handlerName, EventSubscriber handler)
    {
        if (!subscriptions.TryGetValue(eventName, out var list))
        {
            list = [];
            subscriptions[eventName] = list;
        }
        list.Add((handlerName, handler));
    }

    /// <summary>
    /// Delivers `envelope` to every subscriber. When any fails, the relay retries the event
    /// for all of them, which idempotent handlers tolerate.
    /// </summary>
    public async Task Dispatch(Envelope envelope, CancellationToken cancellationToken)
    {
        var failures = new List<string>();
        foreach (var (name, handler) in subscriptions.GetValueOrDefault(envelope.Name) ?? [])
        {
            try
            {
                await handler(envelope, cancellationToken);
            }
            catch (Exception error) when (error is not OperationCanceledException)
            {
                failures.Add($"{name}: {error.Message}");
            }
        }
        if (failures.Count > 0)
        {
            throw new EventDeliveryException(string.Join('\n', failures));
        }
    }
}

/// <summary>Thrown when one or more subscribers failed an event.</summary>
public sealed class EventDeliveryException(string message) : Exception(message);
