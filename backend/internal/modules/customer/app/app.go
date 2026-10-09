// Package app holds the customer use cases: profile, saved addresses and the
// launch-area check.
package app

import (
	"context"
	"strings"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the customer collaborators.
type Deps struct {
	Repo     port.Repository
	Media    port.Media
	Accounts port.Accounts
	Area     port.Area
	Clock    clock.Clock
	IDs      idgen.Generator
}

// Service implements the customer use cases.
type Service struct{ d Deps }

// New returns the customer service.
func New(d Deps) *Service { return &Service{d: d} }

// Profile is what the customer sees of their own profile.
type Profile struct {
	domain.Customer
	Phone    string
	PhotoURL string
}

// Customer returns a stored profile.
func (s *Service) Customer(ctx context.Context, id uuid.UUID) (domain.Customer, error) {
	return s.d.Repo.GetCustomer(ctx, id)
}

// Profile returns the profile with the phone number and a signed photo URL.
func (s *Service) Profile(ctx context.Context, id uuid.UUID) (Profile, error) {
	c, err := s.d.Repo.GetCustomer(ctx, id)
	if err != nil {
		return Profile{}, err
	}
	p := Profile{Customer: c}
	if p.Phone, err = s.d.Accounts.Phone(ctx, id); err != nil {
		return Profile{}, err
	}
	if c.PhotoMediaID != nil {
		p.PhotoURL, err = s.d.Media.URL(ctx, id, *c.PhotoMediaID)
	}
	return p, err
}

// SaveProfile creates or updates the profile. A new photo must be the customer's own
// confirmed avatar upload.
func (s *Service) SaveProfile(ctx context.Context, c domain.Customer) (Profile, error) {
	c.Name = strings.TrimSpace(c.Name)
	if err := c.Validate(); err != nil {
		return Profile{}, err
	}
	if c.PhotoMediaID != nil {
		if err := s.d.Media.AttachAvatar(ctx, c.ID, *c.PhotoMediaID); err != nil {
			return Profile{}, err
		}
	}
	c.UpdatedAt = s.d.Clock.Now()
	if err := s.d.Repo.SaveCustomer(ctx, c, contract.CustomerProfileSaved{CustomerID: c.ID, Name: c.Name}); err != nil {
		return Profile{}, err
	}
	return s.Profile(ctx, c.ID)
}

// Addresses lists a customer's addresses, default first.
func (s *Service) Addresses(ctx context.Context, customerID uuid.UUID) ([]domain.Address, error) {
	return s.d.Repo.ListAddresses(ctx, customerID)
}

// Address returns one of the customer's addresses.
func (s *Service) Address(ctx context.Context, customerID, addressID uuid.UUID) (domain.Address, error) {
	return s.d.Repo.GetAddress(ctx, customerID, addressID)
}

// AddAddress saves a new address (up to domain.MaxAddresses).
func (s *Service) AddAddress(ctx context.Context, a domain.Address) (domain.Address, error) {
	if err := a.Validate(); err != nil {
		return domain.Address{}, err
	}
	a.ID, a.CreatedAt = s.d.IDs.New(), s.d.Clock.Now()
	return s.d.Repo.AddAddress(ctx, a, domain.MaxAddresses)
}

// UpdateAddress edits an address.
func (s *Service) UpdateAddress(ctx context.Context, a domain.Address) (domain.Address, error) {
	if err := a.Validate(); err != nil {
		return domain.Address{}, err
	}
	a.UpdatedAt = s.d.Clock.Now()
	if err := s.d.Repo.UpdateAddress(ctx, a); err != nil {
		return domain.Address{}, err
	}
	return s.d.Repo.GetAddress(ctx, a.CustomerID, a.ID)
}

// SetDefault makes an address the default.
func (s *Service) SetDefault(ctx context.Context, customerID, addressID uuid.UUID) (domain.Address, error) {
	if err := s.d.Repo.SetDefault(ctx, customerID, addressID); err != nil {
		return domain.Address{}, err
	}
	return s.d.Repo.GetAddress(ctx, customerID, addressID)
}

// DeleteAddress removes an address.
func (s *Service) DeleteAddress(ctx context.Context, customerID, addressID uuid.UUID) error {
	return s.d.Repo.DeleteAddress(ctx, customerID, addressID)
}

// Covered reports whether p lies inside the launch area (C35).
func (s *Service) Covered(ctx context.Context, p geo.Point) (bool, error) {
	area, err := s.d.Area.ServiceArea(ctx)
	if err != nil {
		return false, err
	}
	return domain.Covers(area, domain.Point(p)), nil
}
