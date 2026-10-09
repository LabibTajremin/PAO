package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
)

// Snapshot is a sub-service with its service, as copied onto a booking.
type Snapshot struct {
	SubService domain.SubService
	Service    domain.Service
}

// Snapshot returns the current price version of a sub-service (contract GetPriceSnapshot).
func (s *Service) Snapshot(ctx context.Context, subID uuid.UUID) (Snapshot, error) {
	sub, err := s.d.Repo.SubService(ctx, subID)
	if err != nil {
		return Snapshot{}, err
	}
	svc, err := s.d.Repo.Service(ctx, sub.ServiceID)
	return Snapshot{SubService: sub, Service: svc}, err
}

// GetService returns any service, published or not (contract GetService).
func (s *Service) GetService(ctx context.Context, id uuid.UUID) (domain.Service, error) {
	return s.d.Repo.Service(ctx, id)
}

// ListPublishedServices returns every published service (contract ListServices).
func (s *Service) ListPublishedServices(ctx context.Context) ([]domain.Service, error) {
	tree, err := s.PublishedTree(ctx)
	if err != nil {
		return nil, err
	}
	out := []domain.Service{}
	for _, c := range tree.Categories {
		out = append(out, c.Services...)
	}
	return out, nil
}
