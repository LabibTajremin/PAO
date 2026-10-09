package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
)

type pending struct{ err error }

func (p pending) CountPendingReviews(context.Context) (int, error) { return 4, p.err }

type dashboardRepo struct {
	*fakeRepo
	since time.Time
}

func (r *dashboardRepo) Dashboard(_ context.Context, since time.Time) (domain.Dashboard, []domain.DayCount, error) {
	r.since = since
	return domain.Dashboard{OpenComplaints: 2}, []domain.DayCount{{Date: since, Total: 4, Completed: 3}}, r.err
}

func TestDashboard_CachedAndFailures(t *testing.T) {
	s, base, cache := newService()
	repo := &dashboardRepo{fakeRepo: base}
	s.d.Repo = repo
	s.Connect(Peers{Verification: pending{}})
	ctx := context.Background()
	d, err := s.Dashboard(ctx)
	if err != nil || d.PendingVerifications != 4 || d.OpenComplaints != 2 || d.CompletionRate != 0.75 || len(d.BookingsPerDay) != domain.DashboardDays ||
		!d.BookingsPerDay[0].Date.Equal(repo.since) || len(cache.data) != 1 {
		t.Fatalf("dashboard: %+v %v", d, err)
	}
	base.err = errBoom
	if d, err := s.Dashboard(ctx); err != nil || d.PendingVerifications != 4 {
		t.Fatalf("cached: %+v %v", d, err)
	}
	cache.data, cache.err = map[string][]byte{}, errBoom
	if _, err := s.Dashboard(ctx); !errors.Is(err, errBoom) {
		t.Fatalf("repo down: %v", err)
	}
	base.err = nil
	if _, err := s.Dashboard(ctx); err != nil {
		t.Fatalf("cache down: %v", err)
	}
	s.Connect(Peers{Verification: pending{err: errBoom}})
	if _, err := s.Dashboard(ctx); !errors.Is(err, errBoom) {
		t.Fatalf("verification down: %v", err)
	}
}
