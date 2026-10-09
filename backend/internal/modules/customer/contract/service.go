// Package contract is the customer module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
)

// CustomerService is what other modules may ask of the customer module.
type CustomerService interface {
	// GetCustomer returns a customer profile, or ErrCustomerNotFound.
	GetCustomer(ctx context.Context, customerID uuid.UUID) (Customer, error)
	// GetAddress returns one of the customer's saved addresses with its exact location.
	// Callers must only reveal it to a provider after acceptance (PRD §11).
	GetAddress(ctx context.Context, customerID, addressID uuid.UUID) (Address, error)
	// IsInServiceArea reports whether a point lies inside an active launch area (C35).
	IsInServiceArea(ctx context.Context, point geo.Point) (bool, error)
	// SearchCustomers lists customers with a profile for the admin console, newest first (A-05).
	SearchCustomers(ctx context.Context, q CustomerQuery) ([]CustomerRecord, error)
}
