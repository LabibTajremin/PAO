// Package app holds the admin use cases.
package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// settingsTTL bounds staleness if an invalidation is lost; edits delete the key at once.
const settingsTTL = 10 * time.Minute

// Deps are the admin collaborators.
type Deps struct {
	Repo     port.Repository
	Cache    port.Cache
	Keys     redisx.Keys
	Clock    clock.Clock
	IDs      idgen.Generator
	Log      *slog.Logger
	Bookings port.Bookings
	Media    port.Media
	Admins   port.Admins
}

// Service implements the admin use cases.
type Service struct{ d Deps }

// New returns the admin service.
func New(d Deps) *Service { return &Service{d: d} }

func (s *Service) cacheKey() string { return s.d.Keys.Key("cache", "settings") }

// Settings lists every setting.
func (s *Service) Settings(ctx context.Context) ([]domain.Setting, error) {
	return s.d.Repo.ListSettings(ctx)
}

// Values returns setting values by key, served from the cache when possible. A cache
// failure falls back to the database: settings must never block a booking.
func (s *Service) Values(ctx context.Context) (map[string]string, error) {
	values := map[string]string{}
	if raw, ok, err := s.d.Cache.Get(ctx, s.cacheKey()); err == nil && ok && json.Unmarshal(raw, &values) == nil {
		return values, nil
	}
	list, err := s.d.Repo.ListSettings(ctx)
	if err != nil {
		return nil, err
	}
	for _, st := range list {
		values[st.Key] = st.Value
	}
	raw, _ := json.Marshal(values)
	if err := s.d.Cache.Set(ctx, s.cacheKey(), raw, settingsTTL); err != nil {
		s.d.Log.WarnContext(ctx, "settings cache write failed", "err", err)
	}
	return values, nil
}

// UpdateSetting validates and saves a value; the change is audited through the
// SettingChanged event and the cache is dropped so readers see it at once.
func (s *Service) UpdateSetting(ctx context.Context, actor uuid.UUID, key, value string) (domain.Setting, error) {
	st, err := s.d.Repo.GetSetting(ctx, key)
	if err != nil {
		return domain.Setting{}, err
	}
	if err := domain.Validate(st.Type, value); err != nil {
		return domain.Setting{}, err
	}
	before := st.Value
	st.Value, st.UpdatedAt, st.UpdatedBy = value, s.d.Clock.Now(), &actor
	if err := s.d.Repo.UpdateSetting(ctx, st, contract.SettingChanged{Key: key, Before: before, After: value, ActorID: actor}); err != nil {
		return domain.Setting{}, err
	}
	if err := s.d.Cache.Delete(ctx, s.cacheKey()); err != nil {
		s.d.Log.ErrorContext(ctx, "settings cache invalidation failed", "err", err)
	}
	return st, nil
}

// CountVerifiedComplaints counts verified complaints against a person.
func (s *Service) CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error) {
	return s.d.Repo.CountVerifiedComplaints(ctx, againstID)
}
