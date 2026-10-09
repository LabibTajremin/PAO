// Package contract is the rating module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// RatingService is what other modules may ask of the rating module.
type RatingService interface {
	// GetProviderRating returns the provider's aggregate (zero values when unrated).
	GetProviderRating(ctx context.Context, providerID uuid.UUID) (Summary, error)
	// GetProviderRatings returns aggregates for many providers, for search ranking.
	GetProviderRatings(ctx context.Context, providerIDs []uuid.UUID) (map[uuid.UUID]Summary, error)
	// GetCustomerRating returns the aggregate providers gave a customer (M16).
	GetCustomerRating(ctx context.Context, customerID uuid.UUID) (Summary, error)
}
