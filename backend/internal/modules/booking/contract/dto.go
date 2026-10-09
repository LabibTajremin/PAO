package contract

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Status is a booking state from docs/booking-states.md.
type Status string

// Booking states.
const (
	StatusRequested  Status = "requested"
	StatusAccepted   Status = "accepted"
	StatusOnTheWay   Status = "on_the_way"
	StatusArrived    Status = "arrived"
	StatusInProgress Status = "in_progress"
	StatusCompleted  Status = "completed"
	StatusRejected   Status = "rejected"
	StatusTimedOut   Status = "timed_out"
	StatusCancelled  Status = "cancelled"
)

// Booking is the cross-module view of a booking.
type Booking struct {
	ID           uuid.UUID
	Number       string
	Status       Status
	CustomerID   uuid.UUID
	ProviderID   uuid.UUID
	ServiceID    uuid.UUID
	ServiceName  i18n.Text
	CustomerName string
	ProviderName string
	Area         string
	TotalPaisa   int64
	CreatedAt    time.Time
	CompletedAt  *time.Time
}

// Summary is a compact list entry.
type Summary struct {
	ID          uuid.UUID
	Number      string
	Status      Status
	ServiceName i18n.Text
	TotalPaisa  int64
	CreatedAt   time.Time
}

// ProviderStats are counters derived from a provider's bookings.
type ProviderStats struct {
	CompletedJobs    int
	Cancellations30d int
}

// ErrBookingNotFound is returned for an unknown booking.
var ErrBookingNotFound = errors.New("booking not found")
