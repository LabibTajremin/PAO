// Package app holds the rating use cases.
package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Service implements the rating use cases.
type Service struct {
	repo  port.Repository
	clock clock.Clock
	ids   idgen.Generator
}

// New returns the rating service.
func New(repo port.Repository, clk clock.Clock, ids idgen.Generator) *Service {
	return &Service{repo: repo, clock: clk, ids: ids}
}

// Completed makes a booking reviewable by both sides.
func (s *Service) Completed(ctx context.Context, b domain.Reviewable) error {
	return s.repo.AddReviewable(ctx, b)
}

// Review records one side's review of a completed booking, once per side.
func (s *Service) Review(ctx context.Context, author uuid.UUID, role string, bookingID uuid.UUID, stars int, tags []string, comment string) (domain.Review, error) {
	b, err := s.repo.Reviewable(ctx, bookingID)
	if err != nil {
		return domain.Review{}, err
	}
	r, err := domain.NewReview(b, author, role, stars, tags, comment)
	if err != nil {
		return domain.Review{}, err
	}
	r.ID, r.CreatedAt = s.ids.New(), s.clock.Now()
	_, err = s.repo.Submit(ctx, r, func(a domain.Aggregate) eventbus.Event {
		return contract.ReviewSubmitted{ReviewID: r.ID, BookingID: r.BookingID, AuthorID: author, SubjectID: r.SubjectID,
			SubjectRole: r.SubjectRole(), Stars: stars, NewAverage: a.Average(), NewCount: a.Count}
	})
	return r, err
}

// Summaries returns aggregates for subjects of a role; unrated subjects are zero.
func (s *Service) Summaries(ctx context.Context, role string, ids []uuid.UUID) (map[uuid.UUID]domain.Aggregate, error) {
	return s.repo.Aggregates(ctx, role, ids)
}

// Summary returns one subject's aggregate.
func (s *Service) Summary(ctx context.Context, role string, id uuid.UUID) (domain.Aggregate, error) {
	all, err := s.repo.Aggregates(ctx, role, []uuid.UUID{id})
	return all[id], err
}

// ProviderReviews lists customers' reviews of a provider, newest first.
func (s *Service) ProviderReviews(ctx context.Context, provider uuid.UUID, p port.Page) ([]domain.Review, error) {
	return s.repo.Reviews(ctx, provider, domain.Customer, p)
}
