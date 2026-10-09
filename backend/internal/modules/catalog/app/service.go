// Package app holds the catalog use cases.
package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// cacheTTL bounds how long a rendered tree is kept; the version in the key already
// makes edits visible at once.
const cacheTTL = 10 * time.Minute

// Deps are the collaborators of the catalog use cases.
type Deps struct {
	Repo  port.Repository
	Cache port.Cache
	Keys  interface{ Key(parts ...string) string }
	Clock clock.Clock
	IDs   idgen.Generator
	Log   *slog.Logger
}

// Service implements the catalog use cases.
type Service struct{ d Deps }

// New returns the catalog service.
func New(d Deps) *Service { return &Service{d: d} }

// Tree is a catalog snapshot with its version.
type Tree struct {
	Version    int64
	Categories []domain.Category
}

// PublishedTree returns what customers and providers browse, from the cache when the
// version has not changed (C-03).
func (s *Service) PublishedTree(ctx context.Context) (Tree, error) {
	version, err := s.d.Repo.Version(ctx)
	if err != nil {
		return Tree{}, err
	}
	key := s.d.Keys.Key("cache", "catalog", "v"+strconv.FormatInt(version, 10))
	if raw, ok, err := s.d.Cache.Get(ctx, key); err == nil && ok {
		var cached []domain.Category
		if json.Unmarshal(raw, &cached) == nil {
			return Tree{Version: version, Categories: cached}, nil
		}
	} else if err != nil {
		s.d.Log.WarnContext(ctx, "catalog cache read failed", "error", err)
	}
	all, err := s.d.Repo.Tree(ctx)
	if err != nil {
		return Tree{}, err
	}
	published := domain.Published(all)
	raw, _ := json.Marshal(published)
	if err := s.d.Cache.Set(ctx, key, raw, cacheTTL); err != nil {
		s.d.Log.WarnContext(ctx, "catalog cache write failed", "error", err)
	}
	return Tree{Version: version, Categories: published}, nil
}

// AdminTree returns everything, published or not (A03).
func (s *Service) AdminTree(ctx context.Context) (Tree, error) {
	version, err := s.d.Repo.Version(ctx)
	if err != nil {
		return Tree{}, err
	}
	all, err := s.d.Repo.Tree(ctx)
	return Tree{Version: version, Categories: all}, err
}

// PublishedService returns a published service with its published sub-services (C09).
func (s *Service) PublishedService(ctx context.Context, id uuid.UUID) (domain.Service, error) {
	tree, err := s.PublishedTree(ctx)
	if err != nil {
		return domain.Service{}, err
	}
	for _, c := range tree.Categories {
		for _, svc := range c.Services {
			if svc.ID == id {
				return svc, nil
			}
		}
	}
	return domain.Service{}, domain.ErrNotFound
}

// Search finds published services and sub-services by Bangla or English text (C08).
func (s *Service) Search(ctx context.Context, q string) ([]domain.Service, []domain.SubService, error) {
	serviceIDs, subIDs, err := s.d.Repo.Search(ctx, q)
	if err != nil {
		return nil, nil, err
	}
	tree, err := s.PublishedTree(ctx)
	if err != nil {
		return nil, nil, err
	}
	services, subs := []domain.Service{}, []domain.SubService{}
	byID := map[uuid.UUID]domain.Service{}
	subByID := map[uuid.UUID]domain.SubService{}
	for _, c := range tree.Categories {
		for _, svc := range c.Services {
			byID[svc.ID] = svc
			for _, ss := range svc.SubServices {
				subByID[ss.ID] = ss
			}
		}
	}
	for _, id := range serviceIDs {
		if svc, ok := byID[id]; ok {
			services = append(services, svc)
		}
	}
	for _, id := range subIDs {
		if ss, ok := subByID[id]; ok {
			subs = append(subs, ss)
		}
	}
	return services, subs, nil
}
