// Package inproc implements the verification contract and its background jobs.
package inproc

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
)

// Service adapts the verification use cases to contract.VerificationService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.VerificationService = (*Service)(nil)

// GetLevel implements contract.VerificationService.
func (s *Service) GetLevel(ctx context.Context, id uuid.UUID) (int, error) {
	return s.svc.Level(ctx, id)
}

// GetLevels implements contract.VerificationService.
func (s *Service) GetLevels(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]int, error) {
	return s.svc.Levels(ctx, ids)
}

// CanReceiveBookings implements contract.VerificationService.
func (s *Service) CanReceiveBookings(ctx context.Context, id, serviceID uuid.UUID) (bool, error) {
	return s.svc.CanReceiveBookings(ctx, id, serviceID)
}

// GetItems implements contract.VerificationService.
func (s *Service) GetItems(ctx context.Context, id uuid.UUID) ([]contract.Item, error) {
	return s.svc.Items(ctx, id)
}

// CountPendingReviews implements contract.VerificationService.
func (s *Service) CountPendingReviews(ctx context.Context) (int, error) {
	return s.svc.CountPendingReviews(ctx)
}
