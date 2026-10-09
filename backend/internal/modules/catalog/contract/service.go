// Package contract is the catalog module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// CatalogService is what other modules may ask of the catalog.
type CatalogService interface {
	// GetService returns a service with its rules (radius, level, women-only), or
	// ErrServiceNotFound.
	GetService(ctx context.Context, serviceID uuid.UUID) (Service, error)
	// GetPriceSnapshot returns the current price version of a sub-service so a booking
	// can copy it (PRD §4: past bookings keep the price that applied).
	GetPriceSnapshot(ctx context.Context, subServiceID uuid.UUID) (PriceSnapshot, error)
	// ListServices returns every published service, for enrolment and admin filters.
	ListServices(ctx context.Context) ([]Service, error)
}
