package app

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

var errBoom = errors.New("boom")

type fakeRepo struct {
	states   map[uuid.UUID]domain.State
	events   []eventbus.Event
	blocked  map[string]bool
	expiring []port.ExpiringItem
	reminded map[string]bool
	err      error
	listErr  error
	queue    []port.QueueRow
}

func (f *fakeRepo) Load(_ context.Context, id uuid.UUID) (domain.State, error) {
	if st, ok := f.states[id]; ok {
		return st, f.err
	}
	return domain.NewState(id), f.err
}

func (f *fakeRepo) Change(ctx context.Context, id uuid.UUID, fn port.Change) (domain.State, error) {
	st, err := f.Load(ctx, id)
	if err != nil {
		return st, err
	}
	events, err := fn(&st)
	if err != nil {
		return st, err
	}
	st.NewDocuments, st.NIDChanged = nil, false
	f.states[id], f.events = st, append(f.events, events...)
	return st, nil
}

func (f *fakeRepo) Levels(_ context.Context, ids []uuid.UUID) (map[uuid.UUID]int, error) {
	out := map[uuid.UUID]int{}
	for _, id := range ids {
		out[id] = f.states[id].Level
	}
	return out, f.err
}

func (f *fakeRepo) CountPendingReviews(context.Context) (int, error) { return len(f.states), f.err }

func (f *fakeRepo) Queue(context.Context, port.QueueFilter, port.Page) ([]port.QueueRow, error) {
	return f.queue, f.listErr
}

func (f *fakeRepo) Sessions(context.Context, port.SessionFilter, port.Page) ([]domain.Session, error) {
	return nil, f.listErr
}

func (f *fakeRepo) Session(_ context.Context, id uuid.UUID) (domain.Session, error) {
	for _, st := range f.states {
		if s, ok := st.Session(id); ok {
			return *s, nil
		}
	}
	return domain.Session{}, domain.ErrNotFound
}

func (f *fakeRepo) ExpiredBy(_ context.Context, t time.Time) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	for id, st := range f.states {
		for _, it := range st.Items {
			if it.Status == domain.Approved && it.ExpiresAt != nil && !it.ExpiresAt.After(t) {
				ids = append(ids, id)
				break
			}
		}
	}
	return ids, f.listErr
}

func (f *fakeRepo) ExpiringBetween(context.Context, time.Time, time.Time) ([]port.ExpiringItem, error) {
	return f.expiring, f.listErr
}

func (f *fakeRepo) RemindOnce(_ context.Context, it port.ExpiringItem, days int, e eventbus.Event) (bool, error) {
	key := it.ProviderID.String() + it.ItemType + string(rune('0'+days))
	if f.reminded[key] {
		return false, f.err
	}
	f.reminded[key], f.events = true, append(f.events, e)
	return true, f.err
}

func (f *fakeRepo) NIDBlocked(_ context.Context, hash string) (bool, error) {
	return f.blocked[hash], f.err
}

func (f *fakeRepo) BlockNID(_ context.Context, id uuid.UUID, _ string) error {
	if nid := f.states[id].NID; nid != nil {
		f.blocked[nid.Hash] = true
	}
	return f.err
}

type fakePeers struct {
	providers map[uuid.UUID]provider.Provider
	steps     map[uuid.UUID][]provider.EnrolmentStep
	submitErr error
	mediaErr  error
	err       error
}

func (p *fakePeers) Get(_ context.Context, id uuid.UUID) (provider.Provider, error) {
	got, ok := p.providers[id]
	if !ok {
		return got, domain.ErrNotFound
	}
	return got, p.err
}

func (p *fakePeers) MarkStepDone(_ context.Context, id uuid.UUID, step provider.EnrolmentStep) (provider.EnrolmentStatus, error) {
	p.steps[id] = append(p.steps[id], step)
	return provider.EnrolmentStatus{}, nil
}

func (p *fakePeers) MarkSubmitted(context.Context, uuid.UUID) error { return p.submitErr }

func (p *fakePeers) Attach(context.Context, uuid.UUID, uuid.UUID, ...string) error { return p.mediaErr }

func (p *fakePeers) Service(_ context.Context, id uuid.UUID) (port.Service, error) {
	return port.Service{ID: id, MinLevel: 1}, p.err
}

func (p *fakePeers) Rules(context.Context) (port.Rules, error) {
	return port.Rules{PoliceClearanceValidity: 365 * 24 * time.Hour, Level2CoolingOff: 14 * 24 * time.Hour}, p.err
}

type fakeCipher struct{ broken bool }

func (fakeCipher) Encrypt(b []byte) []byte { return append([]byte("enc:"), b...) }

func (c fakeCipher) Decrypt(b []byte) ([]byte, error) {
	if c.broken {
		return nil, errBoom
	}
	return b[4:], nil
}

func (fakeCipher) LookupHash(v string) string { return "h:" + v }

type fixture struct {
	svc   *Service
	repo  *fakeRepo
	peers *fakePeers
	clock *clock.Fake
	id    uuid.UUID
}

func newFixture() fixture {
	id := uuid.New()
	f := fixture{
		repo: &fakeRepo{states: map[uuid.UUID]domain.State{}, blocked: map[string]bool{}, reminded: map[string]bool{}},
		peers: &fakePeers{providers: map[uuid.UUID]provider.Provider{id: {ID: id, FullName: "Rahim", ServiceIDs: []uuid.UUID{uuid.New()}}},
			steps: map[uuid.UUID][]provider.EnrolmentStep{}},
		clock: clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)),
		id:    id,
	}
	f.svc = New(Deps{Repo: f.repo, Providers: f.peers, Media: f.peers, Catalog: f.peers, Settings: f.peers, Cipher: fakeCipher{},
		Clock: f.clock, IDs: idgen.V7{}})
	return f
}
