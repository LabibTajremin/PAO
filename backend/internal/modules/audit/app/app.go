// Package app holds the audit use cases and the event handlers that turn domain events
// into audit entries.
package app

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Service implements the audit use cases.
type Service struct {
	repo  port.Repository
	clock clock.Clock
	ids   idgen.Generator
}

// New returns the audit service.
func New(repo port.Repository, clk clock.Clock, ids idgen.Generator) *Service {
	return &Service{repo: repo, clock: clk, ids: ids}
}

// Record appends an entry, filling in ID and time.
func (s *Service) Record(ctx context.Context, e domain.Entry) error {
	if err := e.Validate(); err != nil {
		return err
	}
	e.ID = s.ids.New()
	if e.At.IsZero() {
		e.At = s.clock.Now()
	}
	return s.repo.Append(ctx, e)
}

// List returns a page of entries, newest first (A-08).
func (s *Service) List(ctx context.Context, f domain.Filter, p port.Page) ([]domain.Entry, error) {
	return s.repo.List(ctx, f, p)
}
