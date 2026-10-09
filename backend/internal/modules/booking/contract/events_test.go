package contract

import (
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

func TestEventNames(t *testing.T) {
	events := map[string]eventbus.Event{
		"booking.BookingRequested":   BookingRequested{},
		"booking.BookingAccepted":    BookingAccepted{},
		"booking.BookingRejected":    BookingRejected{},
		"booking.BookingTimedOut":    BookingTimedOut{},
		"booking.ProviderOnTheWay":   ProviderOnTheWay{},
		"booking.ProviderArrived":    ProviderArrived{},
		"booking.BookingStarted":     BookingStarted{},
		"booking.ExtraItemsProposed": ExtraItemsProposed{},
		"booking.ExtraItemsDecided":  ExtraItemsDecided{},
		"booking.BookingCompleted":   BookingCompleted{},
		"booking.BookingCancelled":   BookingCancelled{},
	}
	for want, e := range events {
		if got := e.EventName(); got != want {
			t.Errorf("EventName() = %q, want %q", got, want)
		}
	}
}
