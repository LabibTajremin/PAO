// Package port declares what the notification use cases need from adapters.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
)

// Page is a keyset position over (created_at, id); Limit includes the look-ahead row.
type Page struct {
	At    *time.Time
	ID    uuid.UUID
	Limit int
}

// Repository stores the inbox and device tokens.
type Repository interface {
	// Add stores a notification and reports false when its dedupe key was seen before.
	Add(ctx context.Context, n domain.Notification) (bool, error)
	List(ctx context.Context, recipient uuid.UUID, app string, p Page) ([]domain.Notification, error)
	Unread(ctx context.Context, recipient uuid.UUID, app string) (int, error)
	MarkRead(ctx context.Context, recipient uuid.UUID, app string, id uuid.UUID, at time.Time) error
	MarkAllRead(ctx context.Context, recipient uuid.UUID, app string, at time.Time) error
	SaveToken(ctx context.Context, token string, account uuid.UUID, app, platform string, at time.Time) error
	Tokens(ctx context.Context, account uuid.UUID, app string) ([]string, error)
	DropToken(ctx context.Context, token string) error
	// Forget erases an account's inbox and devices (PRD §11).
	Forget(ctx context.Context, account uuid.UUID) error
}

// Pusher delivers to one device; domain.ErrInvalidToken means the token is dead.
type Pusher interface {
	Push(ctx context.Context, token string, p domain.Push) error
}

// Languages returns a recipient's language ("bn" or "en") for an app.
type Languages interface {
	Language(ctx context.Context, account uuid.UUID, app string) string
}

// Booking is what notifications say about a booking.
type Booking struct {
	Number       string
	ServiceEN    string
	ServiceBN    string
	Area         string
	ProviderName string
	CustomerName string
}

// Bookings reads booking details for message text.
type Bookings interface {
	Booking(ctx context.Context, id uuid.UUID) (Booking, error)
}
