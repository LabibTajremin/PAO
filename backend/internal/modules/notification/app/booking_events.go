package app

import (
	"context"
	"errors"
	"strconv"

	"github.com/google/uuid"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// note is one recipient of a booking event.
type note struct {
	to       uuid.UUID
	app      string
	template string
	extra    map[string]string
}

func customer(p booking.Parties, template string) note {
	return note{to: p.CustomerID, app: "customer", template: template}
}

func provider(p booking.Parties, template string) note {
	return note{to: p.ProviderID, app: "partner", template: template}
}

// bookingNotes decides who hears about each booking event (02-architecture.md §8).
var bookingNotes = map[string]func(env eventbus.Envelope) (booking.Parties, []note, error){
	booking.BookingRequested{}.EventName(): one[booking.BookingRequested](func(e booking.BookingRequested) (booking.Parties, []note) {
		return e.Parties, []note{provider(e.Parties, "booking_requested")}
	}),
	booking.BookingAccepted{}.EventName(): one[booking.BookingAccepted](func(e booking.BookingAccepted) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "booking_accepted")}
	}),
	booking.BookingRejected{}.EventName(): one[booking.BookingRejected](func(e booking.BookingRejected) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "booking_rejected")}
	}),
	booking.BookingTimedOut{}.EventName(): one[booking.BookingTimedOut](func(e booking.BookingTimedOut) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "booking_timed_out"), provider(e.Parties, "request_missed")}
	}),
	booking.ProviderOnTheWay{}.EventName(): one[booking.ProviderOnTheWay](func(e booking.ProviderOnTheWay) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "provider_on_the_way")}
	}),
	booking.ProviderArrived{}.EventName(): one[booking.ProviderArrived](func(e booking.ProviderArrived) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "provider_arrived")}
	}),
	booking.BookingStarted{}.EventName(): one[booking.BookingStarted](func(e booking.BookingStarted) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "booking_started")}
	}),
	booking.ExtraItemsProposed{}.EventName(): one[booking.ExtraItemsProposed](func(e booking.ExtraItemsProposed) (booking.Parties, []note) {
		n := customer(e.Parties, "extras_proposed")
		n.extra = map[string]string{"added": strconv.FormatInt(e.AddedPaisa/100, 10)}
		return e.Parties, []note{n}
	}),
	booking.ExtraItemsDecided{}.EventName(): one[booking.ExtraItemsDecided](func(e booking.ExtraItemsDecided) (booking.Parties, []note) {
		n := provider(e.Parties, "extras_decided")
		n.extra = map[string]string{"decision": "declined"}
		if e.Approved {
			n.extra["decision"] = "approved"
		}
		return e.Parties, []note{n}
	}),
	booking.BookingCompleted{}.EventName(): one[booking.BookingCompleted](func(e booking.BookingCompleted) (booking.Parties, []note) {
		return e.Parties, []note{customer(e.Parties, "booking_completed"), provider(e.Parties, "booking_completed")}
	}),
	booking.BookingCancelled{}.EventName(): one[booking.BookingCancelled](func(e booking.BookingCancelled) (booking.Parties, []note) {
		if e.By == "customer" {
			return e.Parties, []note{provider(e.Parties, "booking_cancelled")}
		}
		return e.Parties, []note{customer(e.Parties, "booking_cancelled")}
	}),
}

// one decodes a typed event and lists the notes it produces.
func one[T eventbus.Event](fn func(T) (booking.Parties, []note)) func(eventbus.Envelope) (booking.Parties, []note, error) {
	return func(env eventbus.Envelope) (booking.Parties, []note, error) {
		e, err := eventbus.Decode[T](env)
		if err != nil {
			return booking.Parties{}, nil, err
		}
		p, notes := fn(e)
		return p, notes, nil
	}
}

func (s *Service) onBooking(build func(eventbus.Envelope) (booking.Parties, []note, error)) eventbus.Handler {
	return func(ctx context.Context, env eventbus.Envelope) error {
		p, notes, err := build(env)
		if err != nil {
			return err
		}
		b, err := s.d.Bookings.Booking(ctx, p.BookingID)
		if errors.Is(err, booking.ErrBookingNotFound) {
			// Retrying cannot make a missing booking appear, so the event is dropped rather than blocking the outbox.
			s.d.Log.WarnContext(ctx, "notification for unknown booking", "booking", p.BookingID, "event", env.Name)
			return nil
		}
		for _, n := range notes {
			if err == nil {
				lang := s.d.Languages.Language(ctx, n.to, n.app)
				data := map[string]string{"number": b.Number, "service": b.ServiceBN, "area": b.Area, "provider": b.ProviderName, "customer": b.CustomerName}
				if lang == "en" {
					data["service"] = b.ServiceEN
				}
				for k, v := range n.extra {
					data[k] = v
				}
				id := p.BookingID
				err = s.Send(ctx, Message{Recipient: n.to, App: n.app, Template: n.template, Data: data, BookingID: &id,
					DedupeKey: env.ID.String() + ":" + n.template, Language: lang})
			}
		}
		return err
	}
}
