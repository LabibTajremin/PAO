package domain

import (
	"time"

	"github.com/google/uuid"
)

// Text is a value in English and Bangla.
type Text struct {
	EN string
	BN string
}

// Point is a WGS84 position.
type Point struct {
	Lat float64
	Lng float64
}

// Line is a priced item copied from the catalog (PRD §9.3 rule 4).
type Line struct {
	ID             uuid.UUID
	SubServiceID   uuid.UUID
	PriceVersionID uuid.UUID
	Name           Text
	Unit           string
	Quantity       int
	UnitPaisa      int64
	TotalPaisa     int64
	Extra          bool
	ProposalID     *uuid.UUID
	Position       int
}

// NewLine prices a line; quantities are validated against the catalog maximum.
func NewLine(id uuid.UUID, sub, version uuid.UUID, name Text, unit string, qty, maxQty int, unitPaisa int64) (Line, error) {
	if qty < 1 || (maxQty > 0 && qty > maxQty) {
		return Line{}, ErrInvalid
	}
	return Line{ID: id, SubServiceID: sub, PriceVersionID: version, Name: name, Unit: unit, Quantity: qty, UnitPaisa: unitPaisa,
		TotalPaisa: unitPaisa * int64(qty)}, nil
}

// Proposal is a set of extra items waiting for the customer.
type Proposal struct {
	ID         uuid.UUID
	Status     string
	AddedPaisa int64
	ProposedAt time.Time
	DecidedAt  *time.Time
	Lines      []Line
}

// Event is one timeline entry.
type Event struct {
	ID     uuid.UUID
	Status string
	Actor  string
	Reason string
	At     time.Time
}

// Party is a snapshot of one side of the booking.
type Party struct {
	ID    uuid.UUID
	Name  string
	Phone string
}

// Address is the service address snapshot.
type Address struct {
	ID       uuid.UUID
	Area     string
	Line1    string
	Line2    string
	Location Point
}

// Booking is the aggregate moved by the state machine.
type Booking struct {
	ID                 uuid.UUID
	Number             int64
	Customer           Party
	Provider           Party
	ServiceID          uuid.UUID
	ServiceName        Text
	ServiceModel       string
	Address            Address
	Note               string
	Status             string
	Scheduled          bool
	ScheduledAt        *time.Time
	EndsAt             *time.Time
	AcceptDeadline     time.Time
	TotalPaisa         int64
	StartCode          string
	CodeAttempts       int
	CodeLockedUntil    *time.Time
	CashReceived       bool
	IdempotencyKey     string
	CancelReason       string
	CancelledBy        string
	RejectReason       string
	CreatedAt          time.Time
	AcceptedAt         *time.Time
	StartedAt          *time.Time
	CompletedAt        *time.Time
	CancelledAt        *time.Time
	Lines              []Line
	Proposals          []Proposal
	Timeline           []Event
	ProviderActiveJobs int
	// NewEvents are timeline entries added since loading.
	NewEvents []Event
}

// Total sums the lines.
func Total(lines []Line) int64 {
	var sum int64
	for _, l := range lines {
		sum += l.TotalPaisa
	}
	return sum
}

// Pending returns the proposal waiting for the customer, if any.
func (b *Booking) Pending() *Proposal {
	for i := range b.Proposals {
		if b.Proposals[i].Status == "pending" {
			return &b.Proposals[i]
		}
	}
	return nil
}

// Cancellable reports whether the customer may still cancel: until the start code is
// entered (D8).
func (b *Booking) Cancellable() bool {
	return CanTransition(b.Status, Cancelled, ByCustomer)
}
