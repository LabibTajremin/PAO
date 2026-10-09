package app

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

var errBoom = errors.New("boom")

type fakeRepo struct {
	rows       map[uuid.UUID]domain.Provider
	events     []eventbus.Event
	err        error
	getErr     error
	candidates []port.Candidate
}

func (f *fakeRepo) Ensure(_ context.Context, id uuid.UUID, phone string, at time.Time) error {
	if f.err == nil {
		f.rows[id] = domain.Provider{ID: id, Phone: phone, AccountStatus: "active", Language: "bn", CreatedAt: at}
	}
	return f.err
}

func (f *fakeRepo) Get(_ context.Context, id uuid.UUID) (domain.Provider, error) {
	if f.getErr != nil {
		return domain.Provider{}, f.getErr
	}
	p, ok := f.rows[id]
	if !ok {
		return p, domain.ErrNotFound
	}
	return p, nil
}

func (f *fakeRepo) Save(_ context.Context, p domain.Provider, events ...eventbus.Event) error {
	if f.err == nil {
		f.rows[p.ID], f.events = p, append(f.events, events...)
	}
	return f.err
}

func (f *fakeRepo) Publish(_ context.Context, _ uuid.UUID, events ...eventbus.Event) error {
	f.events = append(f.events, events...)
	return f.err
}

func (f *fakeRepo) Candidates(context.Context, []uuid.UUID, int) ([]port.Candidate, error) {
	return f.candidates, f.err
}

type fakePresence struct {
	online map[uuid.UUID]domain.Point
	hits   []port.Hit
	lost   []uuid.UUID
	err    error
}

func (p *fakePresence) Online(_ context.Context, id uuid.UUID, _ []uuid.UUID, at domain.Point) error {
	p.online[id] = at
	return p.err
}

func (p *fakePresence) Beat(ctx context.Context, id uuid.UUID, s []uuid.UUID, at domain.Point) error {
	if _, ok := p.online[id]; !ok {
		return domain.ErrOffline
	}
	return p.Online(ctx, id, s, at)
}

func (p *fakePresence) Offline(_ context.Context, id uuid.UUID, _ []uuid.UUID) error {
	delete(p.online, id)
	return p.err
}

func (p *fakePresence) IsOnline(_ context.Context, id uuid.UUID) (bool, error) {
	_, ok := p.online[id]
	return ok, p.err
}

func (p *fakePresence) Near(context.Context, uuid.UUID, domain.Point, int) ([]port.Hit, error) {
	return p.hits, p.err
}

func (p *fakePresence) Lost(context.Context) ([]uuid.UUID, error) { return p.lost, p.err }

type fakePeers struct {
	services map[uuid.UUID]port.Service
	err      error
	codeErr  error
	sent     []string
}

func (f *fakePeers) Service(_ context.Context, id uuid.UUID) (port.Service, error) {
	s, ok := f.services[id]
	if !ok {
		return s, domain.ErrUnknownService
	}
	return s, f.err
}

func (f *fakePeers) Phone(context.Context, uuid.UUID) (string, error) { return "+8801712345678", f.err }

func (f *fakePeers) SendContactCode(_ context.Context, phone string) error {
	f.sent = append(f.sent, phone)
	return f.codeErr
}

func (f *fakePeers) CheckContactCode(context.Context, string, string) error { return f.codeErr }

func (f *fakePeers) AttachAvatar(context.Context, uuid.UUID, uuid.UUID) error { return f.err }

func (f *fakePeers) URL(context.Context, uuid.UUID, uuid.UUID) (string, error) {
	return "https://photo", f.err
}

type fixture struct {
	svc      *Service
	repo     *fakeRepo
	presence *fakePresence
	peers    *fakePeers
	clock    *clock.Fake
	electric uuid.UUID
}

func newFixture() fixture {
	electric := uuid.New()
	f := fixture{
		repo:     &fakeRepo{rows: map[uuid.UUID]domain.Provider{}},
		presence: &fakePresence{online: map[uuid.UUID]domain.Point{}},
		peers:    &fakePeers{services: map[uuid.UUID]port.Service{electric: {ID: electric, Published: true, MinLevel: 1}}},
		clock:    clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)),
		electric: electric,
	}
	f.svc = New(Deps{Repo: f.repo, Presence: f.presence, Catalog: f.peers, Accounts: f.peers, Media: f.peers, Clock: f.clock, Log: logx.Discard()})
	return f
}
