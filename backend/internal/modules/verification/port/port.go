// Package port declares what the verification use cases need from adapters and other
// modules.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Change mutates a provider's state and returns the events to publish with it.
type Change func(s *domain.State) ([]eventbus.Event, error)

// Page is a keyset position over (time, id); Limit includes the look-ahead row.
type Page struct {
	At    *time.Time
	ID    uuid.UUID
	Limit int
}

// QueueFilter narrows the review queue (A-03).
type QueueFilter struct {
	ItemType  string
	ServiceID *uuid.UUID
}

// QueueRow is a submitted provider with items waiting for a decision.
type QueueRow struct {
	ProviderID   uuid.UUID
	SubmittedAt  time.Time
	PendingItems []string
	ServiceIDs   []uuid.UUID
}

// SessionFilter narrows the Level 2 session list.
type SessionFilter struct {
	ProviderID *uuid.UUID
	Status     string
}

// ExpiringItem is an approved item with an expiry date.
type ExpiringItem struct {
	ProviderID uuid.UUID
	ItemType   string
	ExpiresAt  time.Time
}

// Repository stores verification state. Change runs under the provider's row lock, so
// concurrent decisions cannot compute the level from stale items.
type Repository interface {
	Load(ctx context.Context, id uuid.UUID) (domain.State, error)
	Change(ctx context.Context, id uuid.UUID, fn Change) (domain.State, error)
	Levels(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]int, error)
	CountPendingReviews(ctx context.Context) (int, error)
	Queue(ctx context.Context, f QueueFilter, p Page) ([]QueueRow, error)
	Sessions(ctx context.Context, f SessionFilter, p Page) ([]domain.Session, error)
	Session(ctx context.Context, id uuid.UUID) (domain.Session, error)
	// ExpiredBy lists providers with approved items whose expiry is at or before t.
	ExpiredBy(ctx context.Context, t time.Time) ([]uuid.UUID, error)
	// ExpiringBetween lists approved items expiring in (from, to].
	ExpiringBetween(ctx context.Context, from, to time.Time) ([]ExpiringItem, error)
	// RemindOnce records a reminder and reports whether it was new.
	RemindOnce(ctx context.Context, it ExpiringItem, daysBefore int, e eventbus.Event) (bool, error)
	NIDBlocked(ctx context.Context, hash string) (bool, error)
	// BlockNID adds the provider's NID hash to the block list (PRD §6.4: banned
	// identities cannot re-register).
	BlockNID(ctx context.Context, id uuid.UUID, reason string) error
}

// Providers reaches the provider module.
type Providers interface {
	Get(ctx context.Context, id uuid.UUID) (provider.Provider, error)
	MarkStepDone(ctx context.Context, id uuid.UUID, step provider.EnrolmentStep) (provider.EnrolmentStatus, error)
	MarkSubmitted(ctx context.Context, id uuid.UUID) error
}

// Media checks uploads used as verification documents.
type Media interface {
	// Attach checks the upload is the owner's confirmed file of an allowed purpose and
	// spares it from the orphan purge.
	Attach(ctx context.Context, owner, id uuid.UUID, purposes ...string) error
}

// Service is the catalog's view of a service: its name and the level it requires
// (Level 2 when the service demands it, PRD §6.1).
type Service struct {
	ID       uuid.UUID
	Name     i18n.Text
	MinLevel int
}

// Catalog reads services.
type Catalog interface {
	Service(ctx context.Context, id uuid.UUID) (Service, error)
}

// Rules are the admin-editable verification settings.
type Rules struct {
	PoliceClearanceValidity time.Duration
	Level2CoolingOff        time.Duration
}

// Settings reads the rules.
type Settings interface {
	Rules(ctx context.Context) (Rules, error)
}

// Cipher encrypts NID numbers and derives their lookup hash.
type Cipher interface {
	Encrypt(plaintext []byte) []byte
	Decrypt(data []byte) ([]byte, error)
	LookupHash(value string) string
}
