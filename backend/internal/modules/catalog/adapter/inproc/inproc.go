// Package inproc implements the catalog contract for other modules in the process.
package inproc

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Service adapts the catalog use cases to contract.CatalogService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.CatalogService = (*Service)(nil)

// GetService implements contract.CatalogService.
func (s *Service) GetService(ctx context.Context, id uuid.UUID) (contract.Service, error) {
	svc, err := s.svc.GetService(ctx, id)
	if errors.Is(err, domain.ErrNotFound) {
		return contract.Service{}, errors.Join(contract.ErrServiceNotFound, err)
	}
	return toService(svc), err
}

// GetPriceSnapshot implements contract.CatalogService.
func (s *Service) GetPriceSnapshot(ctx context.Context, subServiceID uuid.UUID) (contract.PriceSnapshot, error) {
	snap, err := s.svc.Snapshot(ctx, subServiceID)
	if errors.Is(err, domain.ErrNotFound) {
		return contract.PriceSnapshot{}, errors.Join(contract.ErrSubServiceNotFound, err)
	}
	sub := snap.SubService
	return contract.PriceSnapshot{
		SubServiceID: sub.ID, ServiceID: sub.ServiceID, PriceVersionID: sub.PriceVersionID, Name: text(sub.Name),
		Unit: contract.PriceUnit(sub.Unit), AmountPaisa: sub.Price, MaxQuantity: sub.MaxQuantity,
		Published: sub.Published && snap.Service.Published,
	}, err
}

// ListServices implements contract.CatalogService.
func (s *Service) ListServices(ctx context.Context) ([]contract.Service, error) {
	list, err := s.svc.ListPublishedServices(ctx)
	out := make([]contract.Service, 0, len(list))
	for _, svc := range list {
		out = append(out, toService(svc))
	}
	return out, err
}

func text(n domain.Name) i18n.Text { return i18n.Text{EN: n.EN, BN: n.BN} }

func toService(s domain.Service) contract.Service {
	checklist := make([]i18n.Text, len(s.Level2Checklist))
	for i, n := range s.Level2Checklist {
		checklist[i] = text(n)
	}
	return contract.Service{
		ID: s.ID, CategoryID: s.CategoryID, Name: text(s.Name), Model: contract.ServiceModel(s.Model),
		RequiredLevel: s.RequiredLevel, SearchRadiusM: s.SearchRadiusM, WomenProvidersOnly: s.WomenProvidersOnly,
		RequiresLevel2: s.RequiresLevel2, Level2Checklist: checklist, Published: s.Published,
	}
}
