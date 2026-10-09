package app

import (
	"context"
	"encoding/json"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
)

// dashboardTTL keeps the dashboard cheap under refreshes; a minute-old count is fine.
const dashboardTTL = time.Minute

// Dashboard returns the admin home numbers (A-09), cached for a minute.
func (s *Service) Dashboard(ctx context.Context) (domain.Dashboard, error) {
	key := s.d.Keys.Key("cache", "dashboard")
	var d domain.Dashboard
	if raw, ok, err := s.d.Cache.Get(ctx, key); err == nil && ok && json.Unmarshal(raw, &d) == nil {
		return d, nil
	}
	now := s.d.Clock.Now().In(clock.Dhaka)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	d, days, err := s.d.Repo.Dashboard(ctx, today.AddDate(0, 0, 1-domain.DashboardDays))
	if err == nil {
		d.PendingVerifications, err = s.d.Verification.CountPendingReviews(ctx)
	}
	if err != nil {
		return domain.Dashboard{}, err
	}
	d.BookingsPerDay, d.CompletionRate = domain.FillDays(today, days)
	d.GeneratedAt = s.d.Clock.Now()
	raw, _ := json.Marshal(d)
	if err := s.d.Cache.Set(ctx, key, raw, dashboardTTL); err != nil {
		s.d.Log.WarnContext(ctx, "dashboard cache write failed", "err", err)
	}
	return d, nil
}
