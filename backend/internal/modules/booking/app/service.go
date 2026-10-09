// Package app holds the booking use cases: create, respond, progress, extras, cancel,
// read models, earnings and discovery (PRD §5).
package app

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the booking collaborators.
type Deps struct {
	Repo      port.Repository
	Catalog   port.Catalog
	Customers port.Customers
	Providers port.Providers
	Finder    port.Finder
	Media     port.Media
	Settings  port.Settings
	Clock     clock.Clock
	IDs       idgen.Generator
	// Code returns a fresh 4-digit start code from a CSPRNG.
	Code func() string
	// Dhaka is the calendar used for earnings periods.
	Dhaka *time.Location
}

// Service implements the booking use cases.
type Service struct{ d Deps }

// New returns the booking service.
func New(d Deps) *Service { return &Service{d: d} }

// Number formats a booking number for people (e.g. PAO-104233).
func Number(n int64) string { return fmt.Sprintf("PAO-%d", n) }

func (s *Service) parties(b domain.Booking) contract.Parties {
	return contract.Parties{BookingID: b.ID, Number: Number(b.Number), CustomerID: b.Customer.ID, ProviderID: b.Provider.ID,
		ServiceID: b.ServiceID, At: s.d.Clock.Now()}
}

// change applies fn to a booking that belongs to party, hiding other people's bookings
// as not found.
func (s *Service) change(ctx context.Context, id, party uuid.UUID, fn func(b *domain.Booking) ([]eventbus.Event, error)) (domain.Booking, error) {
	return s.d.Repo.Change(ctx, id, func(b *domain.Booking) ([]eventbus.Event, error) {
		if party != uuid.Nil && b.Customer.ID != party && b.Provider.ID != party {
			return nil, domain.ErrNotFound
		}
		return fn(b)
	})
}

// owned loads a booking that belongs to party.
func (s *Service) owned(ctx context.Context, id, party uuid.UUID) (domain.Booking, error) {
	b, err := s.d.Repo.Get(ctx, id)
	if err == nil && b.Customer.ID != party && b.Provider.ID != party {
		err = domain.ErrNotFound
	}
	return b, err
}
