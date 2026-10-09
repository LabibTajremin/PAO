package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
)

var (
	ctx     = context.Background()
	errBoom = errors.New("boom")
)

type memRepo struct {
	objs  map[uuid.UUID]domain.Object
	fault map[string]error
}

func (m *memRepo) Create(_ context.Context, o domain.Object) error {
	m.objs[o.ID] = o
	return m.fault["Create"]
}

func (m *memRepo) Get(_ context.Context, id uuid.UUID) (domain.Object, error) {
	o, ok := m.objs[id]
	if !ok {
		return o, domain.ErrNotFound
	}
	return o, m.fault["Get"]
}

func (m *memRepo) MarkConfirmed(_ context.Context, id uuid.UUID) error {
	o := m.objs[id]
	o.Confirmed = true
	m.objs[id] = o
	return m.fault["MarkConfirmed"]
}

func (m *memRepo) MarkAttached(_ context.Context, id uuid.UUID) error {
	o := m.objs[id]
	o.Attached = true
	m.objs[id] = o
	return m.fault["MarkAttached"]
}

func (m *memRepo) Delete(_ context.Context, id uuid.UUID) error {
	delete(m.objs, id)
	return m.fault["Delete"]
}

func (m *memRepo) Orphans(_ context.Context, before time.Time) ([]domain.Object, error) {
	var out []domain.Object
	for _, o := range m.objs {
		if !o.Attached && o.CreatedAt.Before(before) {
			out = append(out, o)
		}
	}
	return out, m.fault["Orphans"]
}

type memStore struct {
	files map[string]storage.ObjectInfo
	fault map[string]error
}

func (s *memStore) PresignPut(_ context.Context, _, key, ct string, size int64, _ time.Duration) (string, map[string]string, error) {
	return "put://" + key, map[string]string{"Content-Type": ct}, s.fault["PresignPut"]
}

func (s *memStore) PresignGet(_ context.Context, _, key string, _ time.Duration) (string, error) {
	return "get://" + key, s.fault["PresignGet"]
}

func (s *memStore) Head(_ context.Context, _, key string) (storage.ObjectInfo, error) {
	if err := s.fault["Head"]; err != nil {
		return storage.ObjectInfo{}, err
	}
	info, ok := s.files[key]
	if !ok {
		return info, storage.ErrObjectNotFound
	}
	return info, nil
}

func (s *memStore) Delete(_ context.Context, _, key string) error {
	delete(s.files, key)
	return s.fault["Delete"]
}

type memAudit struct {
	entries []audit.Entry
	err     error
}

func (a *memAudit) Record(_ context.Context, e audit.Entry) error {
	a.entries = append(a.entries, e)
	return a.err
}

type harness struct {
	svc   *Service
	repo  *memRepo
	store *memStore
	audit *memAudit
	clock *clock.Fake
}

func newHarness() harness {
	h := harness{repo: &memRepo{objs: map[uuid.UUID]domain.Object{}, fault: map[string]error{}},
		store: &memStore{files: map[string]storage.ObjectInfo{}, fault: map[string]error{}}, audit: &memAudit{},
		clock: clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))}
	h.svc = New(Deps{Repo: h.repo, Storage: h.store, Auditor: h.audit, Bucket: "private", Clock: h.clock, IDs: idgen.V7{}})
	return h
}

func (h harness) upload(t *testing.T, owner uuid.UUID, purpose string) Ticket {
	t.Helper()
	tk, err := h.svc.CreateUpload(ctx, owner, "provider", purpose, "image/jpeg", 1000)
	if err != nil {
		t.Fatal(err)
	}
	h.store.files[h.repo.objs[tk.MediaID].Key] = storage.ObjectInfo{Size: 1000, ContentType: "image/jpeg"}
	return tk
}

func TestUploadConfirmAndView(t *testing.T) {
	h := newHarness()
	owner, viewer := uuid.New(), uuid.New()
	tk := h.upload(t, owner, "nid_front")
	if tk.URL == "" || !tk.ExpiresAt.Equal(h.clock.Now().Add(UploadURLTTL)) {
		t.Fatalf("ticket: %+v", tk)
	}
	if _, _, err := h.svc.ViewURL(ctx, tk.MediaID, viewer, "verifier"); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unconfirmed file viewable")
	}
	o, err := h.svc.Confirm(ctx, owner, tk.MediaID)
	if err != nil || !o.Confirmed {
		t.Fatalf("confirm: %v", err)
	}
	if again, err := h.svc.Confirm(ctx, owner, tk.MediaID); err != nil || !again.Confirmed {
		t.Fatal("second confirm")
	}
	url, exp, err := h.svc.ViewURL(ctx, tk.MediaID, viewer, "verifier")
	if err != nil || url == "" || !exp.Equal(h.clock.Now().Add(ViewURLTTL)) || len(h.audit.entries) != 1 || *h.audit.entries[0].ActorID != viewer {
		t.Fatalf("view: %v %+v", err, h.audit.entries)
	}
	avatar := h.upload(t, owner, "avatar")
	_, _ = h.svc.Confirm(ctx, owner, avatar.MediaID)
	if _, _, err := h.svc.ViewURL(ctx, avatar.MediaID, viewer, "customer"); err != nil || len(h.audit.entries) != 1 {
		t.Fatal("avatar view audited")
	}
	if got, err := h.svc.Get(ctx, avatar.MediaID); err != nil || got.Purpose != "avatar" {
		t.Fatal("get")
	}
}

func TestConfirm_Refusals(t *testing.T) {
	h := newHarness()
	owner := uuid.New()
	if _, err := h.svc.CreateUpload(ctx, owner, "customer", "nid_front", "image/jpeg", 1); !errors.Is(err, domain.ErrForbidden) {
		t.Fatal("customer uploaded an NID")
	}
	tk := h.upload(t, owner, "selfie")
	if _, err := h.svc.Confirm(ctx, uuid.New(), tk.MediaID); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("stranger confirmed")
	}
	h.store.files[h.repo.objs[tk.MediaID].Key] = storage.ObjectInfo{Size: 999, ContentType: "image/jpeg"}
	if _, err := h.svc.Confirm(ctx, owner, tk.MediaID); !errors.Is(err, domain.ErrNotUploaded) || len(h.store.files) != 0 {
		t.Fatal("size mismatch accepted or kept")
	}
	if _, err := h.svc.Confirm(ctx, owner, tk.MediaID); !errors.Is(err, domain.ErrNotUploaded) {
		t.Fatal("missing file accepted")
	}
	h.store.fault["Head"] = errBoom
	if _, err := h.svc.Confirm(ctx, owner, tk.MediaID); !errors.Is(err, errBoom) {
		t.Fatal("storage failure hidden")
	}
}

func TestFailures(t *testing.T) {
	owner := uuid.New()
	for _, f := range []string{"Create", "PresignPut"} {
		h := newHarness()
		h.repo.fault[f], h.store.fault[f] = errBoom, errBoom
		if _, err := h.svc.CreateUpload(ctx, owner, "provider", "selfie", "image/jpeg", 1); !errors.Is(err, errBoom) {
			t.Errorf("%s hidden", f)
		}
	}
	h := newHarness()
	tk := h.upload(t, owner, "selfie")
	_, _ = h.svc.Confirm(ctx, owner, tk.MediaID)
	h.audit.err = errBoom
	if _, _, err := h.svc.ViewURL(ctx, tk.MediaID, owner, "verifier"); !errors.Is(err, errBoom) {
		t.Fatal("audit failure must block the view")
	}
	if _, _, err := h.svc.ViewURL(ctx, uuid.New(), owner, "verifier"); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unknown media")
	}
	if err := h.svc.Delete(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("delete unknown")
	}
	h.store.fault["Delete"] = errBoom
	if err := h.svc.Delete(ctx, tk.MediaID); !errors.Is(err, errBoom) {
		t.Fatal("storage delete failure hidden")
	}
}

func TestPurgeOrphans(t *testing.T) {
	h := newHarness()
	owner := uuid.New()
	kept := h.upload(t, owner, "selfie")
	_ = h.svc.MarkAttached(ctx, kept.MediaID)
	h.upload(t, owner, "selfie")
	h.clock.Advance(OrphanAfter + time.Minute)
	if n, err := h.svc.PurgeOrphans(ctx); err != nil || n != 1 || len(h.repo.objs) != 1 {
		t.Fatalf("purge: %d %v", n, err)
	}
	h.upload(t, owner, "selfie")
	h.clock.Advance(OrphanAfter + time.Minute)
	h.store.fault["Delete"] = errBoom
	if _, err := h.svc.PurgeOrphans(ctx); !errors.Is(err, errBoom) {
		t.Fatal("purge failure hidden")
	}
	h.repo.fault["Orphans"] = errBoom
	if _, err := h.svc.PurgeOrphans(ctx); !errors.Is(err, errBoom) {
		t.Fatal("orphan query failure hidden")
	}
}
