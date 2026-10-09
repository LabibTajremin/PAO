// Package port declares what the provider use cases need from adapters and other modules.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Repository stores provider profiles.
type Repository interface {
	// Ensure creates an empty profile on first use.
	Ensure(ctx context.Context, id uuid.UUID, phone string, at time.Time) error
	Get(ctx context.Context, id uuid.UUID) (domain.Provider, error)
	// Save writes the profile fields and services (never the read-model copies) and
	// the events in one transaction.
	Save(ctx context.Context, p domain.Provider, events ...eventbus.Event) error
	// Publish writes events without changing the profile.
	Publish(ctx context.Context, id uuid.UUID, events ...eventbus.Event) error
	// Candidates loads active providers at or above minLevel among ids.
	Candidates(ctx context.Context, ids []uuid.UUID, minLevel int) ([]Candidate, error)
}

// Candidate is a search row with the provider's own working radius.
type Candidate struct {
	domain.Candidate
	WorkingRadiusM int
}

// Hit is a provider position found by the presence index.
type Hit struct {
	ID        uuid.UUID
	DistanceM int
}

// Presence tracks online providers and their live position (PRD §11: never stored
// while offline).
type Presence interface {
	Online(ctx context.Context, id uuid.UUID, services []uuid.UUID, at domain.Point) error
	// Beat refreshes the position, failing with domain.ErrOffline when not online.
	Beat(ctx context.Context, id uuid.UUID, services []uuid.UUID, at domain.Point) error
	Offline(ctx context.Context, id uuid.UUID, services []uuid.UUID) error
	IsOnline(ctx context.Context, id uuid.UUID) (bool, error)
	Near(ctx context.Context, service uuid.UUID, at domain.Point, radiusM int) ([]Hit, error)
	// Lost returns providers marked online whose heartbeat has lapsed.
	Lost(ctx context.Context) ([]uuid.UUID, error)
}

// Service is the catalog's view of a service.
type Service struct {
	ID                 uuid.UUID
	Name               i18n.Text
	Published          bool
	MinLevel           int
	WomenProvidersOnly bool
}

// Catalog reads services.
type Catalog interface {
	Service(ctx context.Context, id uuid.UUID) (Service, error)
}

// Accounts reaches identity: the phone number and one-time codes for the emergency
// contact.
type Accounts interface {
	Phone(ctx context.Context, id uuid.UUID) (string, error)
	SendContactCode(ctx context.Context, phone string) error
	CheckContactCode(ctx context.Context, phone, code string) error
}

// Media checks and shows the profile photo.
type Media interface {
	AttachAvatar(ctx context.Context, owner, id uuid.UUID) error
	URL(ctx context.Context, viewer, id uuid.UUID) (string, error)
}

// Quality are the review thresholds from the admin settings (D13).
type Quality struct {
	RatingFloor      float64
	RatingMinJobs    int
	MaxCancellations int
}

// Settings reads the quality thresholds.
type Settings interface {
	Quality(ctx context.Context) (Quality, error)
}

// Rating is a provider's rating breakdown.
type Rating struct {
	Average      float64
	Count        int
	Distribution [5]int
}

// Ratings reads provider ratings.
type Ratings interface {
	ProviderRating(ctx context.Context, id uuid.UUID) (Rating, error)
}
