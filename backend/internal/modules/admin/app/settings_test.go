package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

var errBoom = errors.New("boom")

type fakeRepo struct {
	settings map[string]domain.Setting
	events   []eventbus.Event
	err      error
}

func (f *fakeRepo) ListSettings(context.Context) ([]domain.Setting, error) {
	out := []domain.Setting{}
	for _, s := range f.settings {
		out = append(out, s)
	}
	return out, f.err
}

func (f *fakeRepo) GetSetting(_ context.Context, key string) (domain.Setting, error) {
	s, ok := f.settings[key]
	if !ok {
		return s, domain.ErrNotFound
	}
	return s, nil
}

func (f *fakeRepo) UpdateSetting(_ context.Context, s domain.Setting, e eventbus.Event) error {
	if f.err != nil {
		return f.err
	}
	f.settings[s.Key], f.events = s, append(f.events, e)
	return nil
}

func (f *fakeRepo) CountVerifiedComplaints(context.Context, uuid.UUID) (int, error) { return 2, f.err }

type fakeCache struct {
	data map[string][]byte
	err  error
}

func (c *fakeCache) Get(_ context.Context, k string) ([]byte, bool, error) {
	v, ok := c.data[k]
	return v, ok, c.err
}

func (c *fakeCache) Set(_ context.Context, k string, v []byte, _ time.Duration) error {
	if c.err == nil {
		c.data[k] = v
	}
	return c.err
}

func (c *fakeCache) Delete(_ context.Context, k string) error {
	delete(c.data, k)
	return c.err
}

func newService() (*Service, *fakeRepo, *fakeCache) {
	repo := &fakeRepo{settings: map[string]domain.Setting{"search.default_radius_m": {Key: "search.default_radius_m", Value: "5000", Type: "integer"}}}
	cache := &fakeCache{data: map[string][]byte{}}
	return New(Deps{Repo: repo, Cache: cache, Keys: redisx.NewKeys("test"), Clock: clock.NewFake(time.Now()), Log: logx.Discard()}), repo, cache
}

func TestValues_CachesUntilAnUpdate(t *testing.T) {
	s, repo, cache := newService()
	ctx := context.Background()
	if v, err := s.Values(ctx); err != nil || v["search.default_radius_m"] != "5000" || len(cache.data) != 1 {
		t.Fatalf("values: %v %v", v, err)
	}
	repo.settings["search.default_radius_m"] = domain.Setting{Key: "search.default_radius_m", Value: "1", Type: "integer"}
	if v, _ := s.Values(ctx); v["search.default_radius_m"] != "5000" {
		t.Fatal("cache not used")
	}
	st, err := s.UpdateSetting(ctx, uuid.New(), "search.default_radius_m", "7000")
	if err != nil || st.Value != "7000" || st.UpdatedBy == nil || len(repo.events) != 1 || len(cache.data) != 0 {
		t.Fatalf("update: %+v %v", st, err)
	}
	if n, _ := s.CountVerifiedComplaints(ctx, uuid.New()); n != 2 {
		t.Fatal("complaints")
	}
	if l, _ := s.Settings(ctx); len(l) != 1 {
		t.Fatal("settings")
	}
}

func TestSettings_Failures(t *testing.T) {
	s, repo, cache := newService()
	ctx := context.Background()
	if _, err := s.UpdateSetting(ctx, uuid.New(), "missing", "1"); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal(err)
	}
	if _, err := s.UpdateSetting(ctx, uuid.New(), "search.default_radius_m", "-1"); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	cache.err = errBoom
	if v, err := s.Values(ctx); err != nil || v["search.default_radius_m"] != "5000" {
		t.Fatalf("cache down: %v %v", v, err)
	}
	if _, err := s.UpdateSetting(ctx, uuid.New(), "search.default_radius_m", "1"); err != nil {
		t.Fatalf("cache down update: %v", err)
	}
	repo.err = errBoom
	if _, err := s.Values(ctx); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := s.UpdateSetting(ctx, uuid.New(), "search.default_radius_m", "2"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}
