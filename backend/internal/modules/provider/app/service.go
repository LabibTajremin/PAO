// Package app holds the provider use cases: enrolment steps, profile, presence and
// nearby search.
package app

import (
	"context"
	"errors"
	"log/slog"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
)

// Deps are the provider collaborators.
type Deps struct {
	Repo     port.Repository
	Presence port.Presence
	Catalog  port.Catalog
	Accounts port.Accounts
	Media    port.Media
	Ratings  port.Ratings
	Clock    clock.Clock
	Log      *slog.Logger
}

// Service implements the provider use cases.
type Service struct{ d Deps }

// New returns the provider service.
func New(d Deps) *Service { return &Service{d: d} }

// Get returns a provider profile.
func (s *Service) Get(ctx context.Context, id uuid.UUID) (domain.Provider, error) {
	return s.d.Repo.Get(ctx, id)
}

// load returns the provider, creating an empty profile on the first enrolment call.
func (s *Service) load(ctx context.Context, id uuid.UUID) (domain.Provider, error) {
	p, err := s.d.Repo.Get(ctx, id)
	if !errors.Is(err, domain.ErrNotFound) {
		return p, err
	}
	phone, err := s.d.Accounts.Phone(ctx, id)
	if err == nil {
		err = s.d.Repo.Ensure(ctx, id, phone, s.d.Clock.Now())
	}
	if err != nil {
		return domain.Provider{}, err
	}
	return s.d.Repo.Get(ctx, id)
}

// Progress is the enrolment wizard state.
type Progress struct {
	Steps     []domain.StepStatus
	Complete  bool
	Submitted bool
}

func progressOf(p domain.Provider) Progress {
	steps, complete := domain.Progress(p.StepsDone)
	return Progress{Steps: steps, Complete: complete, Submitted: p.SubmittedAt != nil}
}

// Enrolment returns the wizard progress; nothing saved yet means every step is open.
func (s *Service) Enrolment(ctx context.Context, id uuid.UUID) (Progress, error) {
	p, err := s.d.Repo.Get(ctx, id)
	if errors.Is(err, domain.ErrNotFound) {
		return progressOf(domain.Provider{}), nil
	}
	if err != nil {
		return Progress{}, err
	}
	return progressOf(p), nil
}

// MarkStepDone records a document step saved by verification.
func (s *Service) MarkStepDone(ctx context.Context, id uuid.UUID, step string) (Progress, error) {
	return s.update(ctx, id, step, func(*domain.Provider) error { return nil })
}

// MarkSubmitted records that the enrolment went to review; every required step must be
// done first.
func (s *Service) MarkSubmitted(ctx context.Context, id uuid.UUID) error {
	p, err := s.load(ctx, id)
	if err != nil {
		return err
	}
	if _, complete := domain.Progress(p.StepsDone); !complete {
		return domain.ErrIncomplete
	}
	now := s.d.Clock.Now()
	p.SubmittedAt = &now
	return s.d.Repo.Save(ctx, p)
}

// IsAvailable reports whether the provider is online now.
func (s *Service) IsAvailable(ctx context.Context, id uuid.UUID) (bool, error) {
	return s.d.Presence.IsOnline(ctx, id)
}
