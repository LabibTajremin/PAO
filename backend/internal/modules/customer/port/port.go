// Package port declares what the customer use cases need from adapters and other modules.
package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Repository stores profiles and addresses. Address writes that touch the default flag
// or the per-customer limit run in one transaction holding the customer's row lock.
type Repository interface {
	SaveCustomer(ctx context.Context, c domain.Customer, e eventbus.Event) error
	GetCustomer(ctx context.Context, id uuid.UUID) (domain.Customer, error)
	// AddAddress inserts a, making it the default when asked or when it is the first.
	AddAddress(ctx context.Context, a domain.Address, limit int) (domain.Address, error)
	UpdateAddress(ctx context.Context, a domain.Address) error
	SetDefault(ctx context.Context, customerID, addressID uuid.UUID) error
	// DeleteAddress removes an address; deleting the default promotes the newest one left.
	DeleteAddress(ctx context.Context, customerID, addressID uuid.UUID) error
	ListAddresses(ctx context.Context, customerID uuid.UUID) ([]domain.Address, error)
	GetAddress(ctx context.Context, customerID, addressID uuid.UUID) (domain.Address, error)
}

// Media is the part of the media contract the profile photo needs.
type Media interface {
	// Avatar checks that id is a confirmed avatar upload owned by owner and marks it
	// attached.
	AttachAvatar(ctx context.Context, owner, id uuid.UUID) error
	// URL returns a short-lived URL for showing a photo.
	URL(ctx context.Context, viewer, id uuid.UUID) (string, error)
}

// Accounts returns sign-in details owned by identity.
type Accounts interface {
	Phone(ctx context.Context, id uuid.UUID) (string, error)
}

// Area returns the launch area GeoJSON from the admin settings.
type Area interface {
	ServiceArea(ctx context.Context) (string, error)
}
