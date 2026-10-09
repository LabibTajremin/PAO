// Package inproc implements the customer contract for other modules in the process.
package inproc

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Service adapts the customer use cases to contract.CustomerService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.CustomerService = (*Service)(nil)

func translate(err error) error {
	switch {
	case errors.Is(err, domain.ErrNotFound):
		return errors.Join(contract.ErrCustomerNotFound, err)
	case errors.Is(err, domain.ErrAddressNotFound):
		return errors.Join(contract.ErrAddressNotFound, err)
	}
	return err
}

// GetCustomer implements contract.CustomerService.
func (s *Service) GetCustomer(ctx context.Context, id uuid.UUID) (contract.Customer, error) {
	c, err := s.svc.Customer(ctx, id)
	return contract.Customer{ID: c.ID, Name: c.Name, PhotoMediaID: c.PhotoMediaID, Language: i18n.Language(c.Language)}, translate(err)
}

// GetAddress implements contract.CustomerService.
func (s *Service) GetAddress(ctx context.Context, customerID, addressID uuid.UUID) (contract.Address, error) {
	a, err := s.svc.Address(ctx, customerID, addressID)
	return contract.Address{ID: a.ID, CustomerID: a.CustomerID, Label: a.Label, Line1: a.Line1, Line2: a.Line2, Area: a.Area,
		Location: geo.Point(a.Location)}, translate(err)
}

// IsInServiceArea implements contract.CustomerService.
func (s *Service) IsInServiceArea(ctx context.Context, p geo.Point) (bool, error) {
	return s.svc.Covered(ctx, p)
}

// SearchCustomers implements contract.CustomerService.
func (s *Service) SearchCustomers(ctx context.Context, q contract.CustomerQuery) ([]contract.CustomerRecord, error) {
	return s.svc.Search(ctx, q)
}
