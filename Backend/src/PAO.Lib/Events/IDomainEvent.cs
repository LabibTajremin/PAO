namespace PAO.Lib.Events;

/// <summary>
/// A domain event (PRD §9.3 rule 5). The name (`area.EventName`) is stable across releases
/// because events are stored in the outbox; payloads hold ids and times as strings and
/// money as integer paisa, so a relayed event equals the published one.
/// </summary>
public interface IDomainEvent
{
    /// <summary>The stable event name, e.g. `booking.BookingAccepted`.</summary>
    string Name { get; }
}
