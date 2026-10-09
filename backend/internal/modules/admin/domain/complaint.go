package domain

import (
	"errors"
	"fmt"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// Complaint errors.
var (
	ErrComplaintNotFound = errors.New("complaint not found")
	ErrBookingNotFound   = errors.New("booking not found")
	ErrInvalidComplaint  = errors.New("complaint is invalid")
	ErrInvalidPhoto      = errors.New("photo is not a confirmed complaint photo of the reporter")
	ErrInvalidAssignee   = errors.New("assignee cannot work complaints")
	ErrInvalidTransition = errors.New("complaint is already resolved")
)

// Complaint statuses (A-07).
const (
	StatusOpen     = "open"
	StatusAssigned = "assigned"
	StatusResolved = "resolved"
)

// MaxComplaintPhotos bounds the evidence a reporter attaches (C-14).
const MaxComplaintPhotos = 5

// Reasons a booking can be reported for.
var Reasons = []string{"no_show", "late", "poor_quality", "overcharge", "damage", "behaviour", "safety", "customer_unavailable", "payment", "other"}

// Complaint is a problem reported on a booking by either side.
type Complaint struct {
	ID           uuid.UUID
	Ticket       int64
	BookingID    uuid.UUID
	ReporterID   uuid.UUID
	ReporterRole string
	AgainstID    uuid.UUID
	Reason       string
	Description  string
	Photos       []uuid.UUID
	Status       string
	AssigneeID   *uuid.UUID
	Resolution   string
	Verified     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
	ResolvedAt   *time.Time
	Comments     []Comment
}

// Comment is an internal support note on a complaint.
type Comment struct {
	ID          uuid.UUID
	ComplaintID uuid.UUID
	AuthorID    uuid.UUID
	Body        string
	At          time.Time
}

// TicketNumber is the reference shown to the reporter and support.
func (c Complaint) TicketNumber() string { return fmt.Sprintf("TCK-%06d", c.Ticket) }

// Validate checks a new complaint's reason, description and photo list.
func (c Complaint) Validate() error {
	n := utf8.RuneCountInString(strings.TrimSpace(c.Description))
	if !slices.Contains(Reasons, c.Reason) || n < 10 || n > 1000 || len(c.Photos) > MaxComplaintPhotos {
		return ErrInvalidComplaint
	}
	seen := map[uuid.UUID]bool{}
	for _, p := range c.Photos {
		if seen[p] {
			return ErrInvalidComplaint
		}
		seen[p] = true
	}
	return nil
}

// Assign hands an unresolved complaint to a support agent; reassigning is allowed.
func (c *Complaint) Assign(to uuid.UUID, at time.Time) error {
	if c.Status == StatusResolved {
		return ErrInvalidTransition
	}
	c.Status, c.AssigneeID, c.UpdatedAt = StatusAssigned, &to, at
	return nil
}

// Resolve closes the complaint; a verified one counts against the other party (§6.4).
func (c *Complaint) Resolve(note string, verified bool, at time.Time) error {
	if c.Status == StatusResolved {
		return ErrInvalidTransition
	}
	if n := utf8.RuneCountInString(strings.TrimSpace(note)); n < 5 || n > 1000 {
		return ErrInvalidComplaint
	}
	c.Status, c.Resolution, c.Verified, c.UpdatedAt, c.ResolvedAt = StatusResolved, note, verified, at, &at
	return nil
}
