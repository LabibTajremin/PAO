# Booking area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| `booking.BookingRequested` |
| `booking.BookingAccepted` |
| `booking.BookingRejected` |
| `booking.BookingTimedOut` |
| `booking.ProviderOnTheWay` |
| `booking.ProviderArrived` |
| `booking.BookingStarted` |
| `booking.ExtraItemsProposed` |
| `booking.ExtraItemsDecided` |
| `booking.BookingCompleted` |
| `booking.BookingCancelled` |
