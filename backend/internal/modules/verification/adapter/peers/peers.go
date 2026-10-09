// Package peers adapts other modules' contracts to the verification ports.
package peers

import (
	"context"
	"errors"
	"slices"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
)

// Providers implements port.Providers.
type Providers struct{ Svc provider.ProviderService }

func providerError(err error) error {
	switch {
	case errors.Is(err, provider.ErrProviderNotFound):
		return errors.Join(domain.ErrNotFound, err)
	case errors.Is(err, provider.ErrEnrolmentIncomplete):
		return errors.Join(domain.ErrEnrolmentPending, err)
	}
	return err
}

// Get implements port.Providers.
func (p Providers) Get(ctx context.Context, id uuid.UUID) (provider.Provider, error) {
	out, err := p.Svc.GetProvider(ctx, id)
	return out, providerError(err)
}

// MarkStepDone implements port.Providers.
func (p Providers) MarkStepDone(ctx context.Context, id uuid.UUID, step provider.EnrolmentStep) (provider.EnrolmentStatus, error) {
	return p.Svc.MarkStepDone(ctx, id, step)
}

// MarkSubmitted implements port.Providers.
func (p Providers) MarkSubmitted(ctx context.Context, id uuid.UUID) error {
	return providerError(p.Svc.MarkSubmitted(ctx, id))
}

// Media implements port.Media.
type Media struct{ Svc media.MediaService }

// Attach implements port.Media.
func (m Media) Attach(ctx context.Context, owner, id uuid.UUID, purposes ...string) error {
	o, err := m.Svc.GetObject(ctx, id)
	if errors.Is(err, media.ErrNotFound) || (err == nil && (o.OwnerID != owner || !o.Confirmed || !slices.Contains(purposes, string(o.Purpose)))) {
		return domain.ErrBadDocument
	}
	if err == nil {
		err = m.Svc.MarkAttached(ctx, id)
	}
	return err
}

// Catalog implements port.Catalog.
type Catalog struct{ Svc catalog.CatalogService }

// Service implements port.Catalog.
func (c Catalog) Service(ctx context.Context, id uuid.UUID) (port.Service, error) {
	s, err := c.Svc.GetService(ctx, id)
	if errors.Is(err, catalog.ErrServiceNotFound) {
		return port.Service{}, errors.Join(domain.ErrInvalid, err)
	}
	minLevel := s.RequiredLevel
	if s.RequiresLevel2 {
		minLevel = 2
	}
	return port.Service{ID: s.ID, Name: s.Name, MinLevel: minLevel}, err
}

// Settings implements port.Settings.
type Settings struct{ Svc admin.AdminService }

// Rules implements port.Settings.
func (s Settings) Rules(ctx context.Context) (port.Rules, error) {
	v, err := s.Svc.GetSettings(ctx)
	return port.Rules{PoliceClearanceValidity: v.PoliceClearanceValidity, Level2CoolingOff: v.Level2CoolingOff}, err
}
