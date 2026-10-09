package app

import (
	"context"
	"errors"
	"sort"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

var (
	errBoom = errors.New("boom")
	ctx     = context.Background()
	name    = domain.Name{EN: "Electrician", BN: "ইলেকট্রিশিয়ান"}
)

type faults map[string]error

type fakeRepo struct {
	faults   faults
	cats     map[uuid.UUID]domain.Category
	services map[uuid.UUID]domain.Service
	subs     map[uuid.UUID]domain.SubService
	prices   []domain.PriceVersion
	version  int64
	events   []eventbus.Event
	treeHits int
	search   [2][]uuid.UUID
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{faults: faults{}, cats: map[uuid.UUID]domain.Category{}, services: map[uuid.UUID]domain.Service{}, subs: map[uuid.UUID]domain.SubService{}, version: 1}
}

func (r *fakeRepo) Tree(context.Context) ([]domain.Category, error) {
	r.treeHits++
	var out []domain.Category
	for _, c := range r.cats {
		for _, s := range r.services {
			if s.CategoryID == c.ID {
				s, _ = r.Service(ctx, s.ID)
				c.Services = append(c.Services, s)
			}
		}
		out = append(out, c)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].SortOrder < out[j].SortOrder })
	return out, r.faults["Tree"]
}

func (r *fakeRepo) CategoryExists(_ context.Context, id uuid.UUID) (bool, error) {
	_, ok := r.cats[id]
	return ok, r.faults["CategoryExists"]
}

func (r *fakeRepo) Service(_ context.Context, id uuid.UUID) (domain.Service, error) {
	s, ok := r.services[id]
	if !ok {
		return s, domain.ErrNotFound
	}
	s.SubServices = nil
	for _, ss := range r.subs {
		if ss.ServiceID == id {
			s.SubServices = append(s.SubServices, ss)
		}
	}
	return s, r.faults["Service"]
}

func (r *fakeRepo) SubService(_ context.Context, id uuid.UUID) (domain.SubService, error) {
	s, ok := r.subs[id]
	if !ok || s.PriceVersionID == uuid.Nil {
		return s, domain.ErrNotFound
	}
	return s, r.faults["SubService"]
}

func (r *fakeRepo) PriceHistory(_ context.Context, id uuid.UUID) ([]domain.PriceVersion, error) {
	var out []domain.PriceVersion
	for i := len(r.prices) - 1; i >= 0; i-- {
		if r.prices[i].SubServiceID == id {
			out = append(out, r.prices[i])
		}
	}
	return out, r.faults["PriceHistory"]
}

func (r *fakeRepo) Search(context.Context, string) ([]uuid.UUID, []uuid.UUID, error) {
	return r.search[0], r.search[1], r.faults["Search"]
}

func (r *fakeRepo) Version(context.Context) (int64, error) { return r.version, r.faults["Version"] }

func (r *fakeRepo) InTx(_ context.Context, fn func(tx port.TxRepository) error) error {
	if err := r.faults["InTx"]; err != nil {
		return err
	}
	return fn(r)
}

func (r *fakeRepo) SaveCategory(_ context.Context, c domain.Category) error {
	r.cats[c.ID] = c
	return r.faults["SaveCategory"]
}

func (r *fakeRepo) SaveService(_ context.Context, s domain.Service) error {
	r.services[s.ID] = s
	return r.faults["SaveService"]
}

func (r *fakeRepo) SaveSubService(_ context.Context, s domain.SubService) error {
	if old, ok := r.subs[s.ID]; ok {
		s.PriceVersionID, s.Price = old.PriceVersionID, old.Price
	}
	r.subs[s.ID] = s
	return r.faults["SaveSubService"]
}

func (r *fakeRepo) AddPrice(_ context.Context, p domain.PriceVersion) error {
	r.prices = append(r.prices, p)
	s := r.subs[p.SubServiceID]
	s.PriceVersionID, s.Price = p.ID, p.Amount
	r.subs[p.SubServiceID] = s
	return r.faults["AddPrice"]
}

func (r *fakeRepo) BumpVersion(context.Context) (int64, error) {
	r.version++
	return r.version, r.faults["BumpVersion"]
}

func (r *fakeRepo) Publish(_ context.Context, _ string, e eventbus.Event) error {
	r.events = append(r.events, e)
	return r.faults["Publish"]
}

type fakeCache struct {
	items          map[string][]byte
	getErr, setErr error
}

func (c *fakeCache) Get(_ context.Context, key string) ([]byte, bool, error) {
	v, ok := c.items[key]
	return v, ok, c.getErr
}

func (c *fakeCache) Set(_ context.Context, key string, v []byte, _ time.Duration) error {
	c.items[key] = v
	return c.setErr
}

func newService() (*Service, *fakeRepo, *fakeCache) {
	repo := newFakeRepo()
	cache := &fakeCache{items: map[string][]byte{}}
	return New(Deps{Repo: repo, Cache: cache, Keys: redisx.NewKeys("t"), Clock: clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)),
		IDs: idgen.V7{}, Log: logx.Discard()}), repo, cache
}

// seedTree builds a published category → service → sub-service (৳500) tree.
func seedTree(t interface{ Fatal(...any) }, s *Service) (domain.Category, domain.Service, domain.SubService) {
	c, err := s.SaveCategory(ctx, domain.Category{Name: name, IconKey: "plug", Published: true})
	if err != nil {
		t.Fatal(err)
	}
	svc, err := s.SaveService(ctx, domain.Service{CategoryID: c.ID, Name: name, IconKey: "bolt", Model: "on_demand", RequiredLevel: 1, SearchRadiusM: 5000, Published: true})
	if err != nil {
		t.Fatal(err)
	}
	sub, err := s.CreateSubService(ctx, domain.SubService{ServiceID: svc.ID, Name: name, Unit: "unit", MaxQuantity: 5, Published: true}, 50000, uuid.New())
	if err != nil {
		t.Fatal(err)
	}
	return c, svc, sub
}
