// Package contract is the provider module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// ProviderService is what other modules may ask of the provider module.
type ProviderService interface {
	// GetProvider returns a provider's profile, or ErrProviderNotFound.
	GetProvider(ctx context.Context, providerID uuid.UUID) (Provider, error)
	// IsAvailable reports whether the provider is online right now.
	IsAvailable(ctx context.Context, providerID uuid.UUID) (bool, error)
	// FindNearby returns verified, online providers registered for the service within
	// its radius: Level 2 first, then by the requested sort (PRD §5, D11).
	FindNearby(ctx context.Context, q NearbyQuery) ([]NearbyProvider, error)
	// Enrolment returns the wizard progress; a provider who has saved nothing yet has
	// every step open.
	Enrolment(ctx context.Context, providerID uuid.UUID) (EnrolmentStatus, error)
	// MarkStepDone records a document step saved by verification.
	MarkStepDone(ctx context.Context, providerID uuid.UUID, step EnrolmentStep) (EnrolmentStatus, error)
	// MarkSubmitted records that the provider sent the enrolment for review.
	MarkSubmitted(ctx context.Context, providerID uuid.UUID) error
	// ForceOffline removes the provider from presence, e.g. after a ban or an expired
	// document.
	ForceOffline(ctx context.Context, providerID uuid.UUID) error
}
