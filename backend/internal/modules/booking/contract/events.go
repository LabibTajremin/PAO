package contract

import (
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Parties identifies who a booking event concerns; every booking event embeds it so
// notification and read models can route without calling back.
type Parties struct {
	BookingID  uuid.UUID
	Number     string
	CustomerID uuid.UUID
	ProviderID uuid.UUID
	ServiceID  uuid.UUID
	At         time.Time
}

// BookingRequested is published when a customer requests a provider.
type BookingRequested struct {
	Parties
	AcceptDeadline time.Time
	Scheduled      bool
	TotalPaisa     int64
}

// BookingAccepted is published when the provider accepts.
type BookingAccepted struct{ Parties }

// BookingRejected is published when the provider rejects.
type BookingRejected struct {
	Parties
	Reason string
}

// BookingTimedOut is published when the accept time limit passes.
type BookingTimedOut struct{ Parties }

// ProviderOnTheWay is published when the provider sets off.
type ProviderOnTheWay struct{ Parties }

// ProviderArrived is published when the provider arrives.
type ProviderArrived struct{ Parties }

// BookingStarted is published after the correct start code is entered.
type BookingStarted struct{ Parties }

// ExtraItemsProposed is published when the provider proposes extra catalog items.
type ExtraItemsProposed struct {
	Parties
	ProposalID    uuid.UUID
	AddedPaisa    int64
	NewTotalPaisa int64
}

// ExtraItemsDecided is published when the customer approves or declines extras.
type ExtraItemsDecided struct {
	Parties
	ProposalID uuid.UUID
	Approved   bool
}

// BookingCompleted is published when the job is complete and cash is confirmed.
type BookingCompleted struct {
	Parties
	TotalPaisa   int64
	CustomerName string
	ProviderName string
	ServiceName  i18n.Text
}

// BookingCancelled is published when either side cancels.
type BookingCancelled struct {
	Parties
	By     string
	Reason string
	// AfterAcceptance is true when the provider had already accepted; provider
	// cancellations after acceptance count against quality (PRD §6.4).
	AfterAcceptance bool
}

// EventName implements eventbus.Event.
func (BookingRequested) EventName() string { return "booking.BookingRequested" }

// EventName implements eventbus.Event.
func (BookingAccepted) EventName() string { return "booking.BookingAccepted" }

// EventName implements eventbus.Event.
func (BookingRejected) EventName() string { return "booking.BookingRejected" }

// EventName implements eventbus.Event.
func (BookingTimedOut) EventName() string { return "booking.BookingTimedOut" }

// EventName implements eventbus.Event.
func (ProviderOnTheWay) EventName() string { return "booking.ProviderOnTheWay" }

// EventName implements eventbus.Event.
func (ProviderArrived) EventName() string { return "booking.ProviderArrived" }

// EventName implements eventbus.Event.
func (BookingStarted) EventName() string { return "booking.BookingStarted" }

// EventName implements eventbus.Event.
func (ExtraItemsProposed) EventName() string { return "booking.ExtraItemsProposed" }

// EventName implements eventbus.Event.
func (ExtraItemsDecided) EventName() string { return "booking.ExtraItemsDecided" }

// EventName implements eventbus.Event.
func (BookingCompleted) EventName() string { return "booking.BookingCompleted" }

// EventName implements eventbus.Event.
func (BookingCancelled) EventName() string { return "booking.BookingCancelled" }
