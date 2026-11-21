namespace PAO.Infrastructure.Events;

/// <summary>
/// An area's event subscribers. Each area that consumes events registers one implementation;
/// the worker subscribes them all to the bus at start.
/// </summary>
public interface IEventSubscriptions
{
    /// <summary>Registers the area's handlers on `bus`.</summary>
    void Subscribe(EventBus bus);
}
