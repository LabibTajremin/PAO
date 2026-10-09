// Package contract is the verification module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// VerificationService is what other modules may ask of verification.
type VerificationService interface {
	// GetLevel returns the provider's verification level (0 when never verified).
	GetLevel(ctx context.Context, providerID uuid.UUID) (int, error)
	// GetLevels returns levels for many providers at once, for search ranking.
	GetLevels(ctx context.Context, providerIDs []uuid.UUID) (map[uuid.UUID]int, error)
	// CanReceiveBookings reports whether the provider may receive bookings for the
	// service: Level ≥ the service's required level (Level 2 when flagged), no expired
	// document and not blocked (PRD §6.1, §6.4). uuid.Nil checks any service.
	CanReceiveBookings(ctx context.Context, providerID, serviceID uuid.UUID) (bool, error)
	// GetItems returns the provider's verification items sorted by type (A-05).
	GetItems(ctx context.Context, providerID uuid.UUID) ([]Item, error)
	// CountPendingReviews counts submitted providers with an item awaiting review (A-09).
	CountPendingReviews(ctx context.Context) (int, error)
}
