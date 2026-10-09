package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// racingRepo reports a request as due that a provider accepted in the meantime.
type racingRepo struct {
	port.Repository
	saved int
}

func (r *racingRepo) Due(context.Context, time.Time) ([]uuid.UUID, error) {
	return []uuid.UUID{uuid.New()}, nil
}

func (r *racingRepo) Change(_ context.Context, _ uuid.UUID, fn port.Change) (domain.Booking, error) {
	b := domain.Booking{Status: domain.Accepted}
	events, err := fn(&b)
	r.saved += len(events)
	return b, err
}

func TestExpireDue_SkipsBookingsThatMovedOn(t *testing.T) {
	repo := &racingRepo{}
	s := New(Deps{Repo: repo, Clock: clock.NewFake(time.Now()), IDs: idgen.V7{}})
	if err := s.ExpireDue(context.Background()); err != nil || repo.saved != 0 {
		t.Fatalf("expire: %v, %d events", err, repo.saved)
	}
}
