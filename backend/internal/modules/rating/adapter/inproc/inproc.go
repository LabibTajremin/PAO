// Package inproc implements the rating contract for other modules in the process.
package inproc

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
)

// Service adapts the rating use cases to contract.RatingService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.RatingService = (*Service)(nil)

func summary(a domain.Aggregate) contract.Summary {
	return contract.Summary{Average: a.Average(), Count: a.Count, Distribution: a.Distribution}
}

// GetProviderRating implements contract.RatingService.
func (s *Service) GetProviderRating(ctx context.Context, id uuid.UUID) (contract.Summary, error) {
	a, err := s.svc.Summary(ctx, domain.Provider, id)
	return summary(a), err
}

// GetProviderRatings implements contract.RatingService.
func (s *Service) GetProviderRatings(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]contract.Summary, error) {
	all, err := s.svc.Summaries(ctx, domain.Provider, ids)
	out := make(map[uuid.UUID]contract.Summary, len(all))
	for id, a := range all {
		out[id] = summary(a)
	}
	return out, err
}

// GetCustomerRating implements contract.RatingService.
func (s *Service) GetCustomerRating(ctx context.Context, id uuid.UUID) (contract.Summary, error) {
	a, err := s.svc.Summary(ctx, domain.Customer, id)
	return summary(a), err
}
