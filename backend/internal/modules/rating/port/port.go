// Package port declares what the rating use cases need from adapters.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Page is a keyset position over (created_at, id); Limit includes the look-ahead row.
type Page struct {
	At    *time.Time
	ID    uuid.UUID
	Limit int
}

// Repository stores reviewable bookings, reviews and aggregates.
type Repository interface {
	AddReviewable(ctx context.Context, b domain.Reviewable) error
	Reviewable(ctx context.Context, bookingID uuid.UUID) (domain.Reviewable, error)
	// Submit stores the review, updates the subject's aggregate and writes the event
	// built from the new aggregate, all in one transaction.
	Submit(ctx context.Context, r domain.Review, event func(domain.Aggregate) eventbus.Event) (domain.Aggregate, error)
	Aggregates(ctx context.Context, role string, ids []uuid.UUID) (map[uuid.UUID]domain.Aggregate, error)
	Reviews(ctx context.Context, subject uuid.UUID, authorRole string, p Page) ([]domain.Review, error)
}
