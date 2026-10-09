// Package port declares what the admin use cases need from adapters.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Repository stores settings and complaints.
type Repository interface {
	ListSettings(ctx context.Context) ([]domain.Setting, error)
	GetSetting(ctx context.Context, key string) (domain.Setting, error)
	// UpdateSetting saves the value and writes the event to the outbox in one transaction.
	UpdateSetting(ctx context.Context, s domain.Setting, e eventbus.Event) error
	CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error)
	// CreateComplaint assigns the ticket number and writes the event built from the
	// stored complaint in the same transaction.
	CreateComplaint(ctx context.Context, c domain.Complaint, event func(domain.Complaint) eventbus.Event) (domain.Complaint, error)
	// GetComplaint returns a complaint with its comments, or domain.ErrComplaintNotFound.
	GetComplaint(ctx context.Context, id uuid.UUID) (domain.Complaint, error)
	ListComplaints(ctx context.Context, f ComplaintFilter) ([]domain.Complaint, error)
	// SaveComplaint applies change to the locked row and writes its event, if any.
	SaveComplaint(ctx context.Context, id uuid.UUID, change func(*domain.Complaint) (eventbus.Event, error)) (domain.Complaint, error)
	AddComment(ctx context.Context, c domain.Comment) error
	CountComplaintsAgainst(ctx context.Context, id uuid.UUID) (int, error)
	// ComplaintsInvolving lists the newest complaints a person reported or received.
	ComplaintsInvolving(ctx context.Context, id uuid.UUID, limit int) ([]domain.Complaint, error)
	// Dashboard returns the read-model counts and stored booking days since a date.
	Dashboard(ctx context.Context, since time.Time) (domain.Dashboard, []domain.DayCount, error)
}

// Verification counts providers waiting for document review.
type Verification interface {
	CountPendingReviews(ctx context.Context) (int, error)
}

// ComplaintFilter selects a page of the complaints queue, newest first.
type ComplaintFilter struct {
	Status     *string
	AssigneeID *uuid.UUID
	At         *time.Time
	ID         uuid.UUID
	Limit      int
}

// Bookings finds who took part in a booking.
type Bookings interface {
	// Parties returns the booking's customer and provider, or domain.ErrBookingNotFound.
	Parties(ctx context.Context, bookingID uuid.UUID) (customerID, providerID uuid.UUID, err error)
}

// Media attaches evidence photos.
type Media interface {
	// AttachComplaintPhotos fails with domain.ErrInvalidPhoto unless every photo is the
	// owner's confirmed complaint photo.
	AttachComplaintPhotos(ctx context.Context, owner uuid.UUID, ids []uuid.UUID) error
}

// Admins answers who may work the complaints queue.
type Admins interface {
	CanWorkComplaints(ctx context.Context, id uuid.UUID) (bool, error)
}

// Cache keeps rebuildable reads.
type Cache interface {
	Get(ctx context.Context, key string) ([]byte, bool, error)
	Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}
