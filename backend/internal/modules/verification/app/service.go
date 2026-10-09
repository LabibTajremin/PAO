// Package app holds the verification use cases: document steps, review decisions,
// levels, Level 2 sessions and expiry.
package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the verification collaborators.
type Deps struct {
	Repo      port.Repository
	Providers port.Providers
	Media     port.Media
	Catalog   port.Catalog
	Settings  port.Settings
	Cipher    port.Cipher
	Clock     clock.Clock
	IDs       idgen.Generator
}

// Service implements the verification use cases.
type Service struct{ d Deps }

// New returns the verification service.
func New(d Deps) *Service { return &Service{d: d} }

// change applies fn and recomputes the level in the same transaction, publishing
// ProviderLevelChanged whenever the level moves (PRD §6.1).
func (s *Service) change(ctx context.Context, id uuid.UUID, reason string, fn port.Change) (domain.State, error) {
	return s.d.Repo.Change(ctx, id, func(st *domain.State) ([]eventbus.Event, error) {
		events, err := fn(st)
		if err != nil {
			return nil, err
		}
		if from, changed := st.Recalc(); changed {
			events = append(events, contract.ProviderLevelChanged{ProviderID: id, From: from, To: st.Level, Reason: reason})
		}
		return events, nil
	})
}

// Level returns a provider's level.
func (s *Service) Level(ctx context.Context, id uuid.UUID) (int, error) {
	st, err := s.d.Repo.Load(ctx, id)
	return st.Level, err
}

// Levels returns levels for many providers; unknown ones are absent.
func (s *Service) Levels(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]int, error) {
	return s.d.Repo.Levels(ctx, ids)
}

// CanReceiveBookings applies the level rules for a service; uuid.Nil asks about any
// service (PRD §6.1, §6.4).
func (s *Service) CanReceiveBookings(ctx context.Context, id, serviceID uuid.UUID) (bool, error) {
	st, err := s.d.Repo.Load(ctx, id)
	var svc port.Service
	if err == nil && serviceID != uuid.Nil {
		svc, err = s.d.Catalog.Service(ctx, serviceID)
	}
	if err != nil {
		return false, err
	}
	return st.CanReceiveBookings(svc.MinLevel), nil
}
