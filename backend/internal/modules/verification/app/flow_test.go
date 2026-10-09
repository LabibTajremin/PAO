package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
)

// enrolled submits every Level 1 item for f.id.
func enrolled(t *testing.T, f fixture) {
	t.Helper()
	ctx := context.Background()
	steps := []func() error{
		func() error { _, err := f.svc.SaveNID(ctx, f.id, "1234567890", uuid.New(), uuid.New()); return err },
		func() error { _, err := f.svc.SaveSelfie(ctx, f.id, uuid.New()); return err },
		func() error {
			_, err := f.svc.SavePoliceClearance(ctx, f.id, uuid.New(), f.clock.Now().AddDate(0, -1, 0))
			return err
		},
		func() error { _, err := f.svc.SaveSkillProof(ctx, f.id, []uuid.UUID{uuid.New()}); return err },
	}
	for _, s := range steps {
		if err := s(); err != nil {
			t.Fatal(err)
		}
	}
	for _, step := range []provider.EnrolmentStep{provider.StepPersonal, provider.StepArea, provider.StepEmergencyContact, provider.StepCodeOfConduct, "nid"} {
		if err := f.svc.OnStepSaved(ctx, f.id, step); err != nil {
			t.Fatal(err)
		}
	}
}

func approveAll(t *testing.T, f fixture, actor uuid.UUID) {
	t.Helper()
	for _, it := range domain.Types {
		if _, err := f.svc.Decide(context.Background(), f.id, it, actor, true, ""); err != nil {
			t.Fatalf("%s: %v", it, err)
		}
	}
}

func TestFlow_SubmitReviewLevelOne(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	actor := uuid.New()
	enrolled(t, f)
	if len(f.peers.steps[f.id]) != 4 {
		t.Fatalf("steps marked: %v", f.peers.steps[f.id])
	}
	st, err := f.svc.Submit(ctx, f.id)
	if err != nil || st.SubmittedAt == nil || len(st.ServiceIDs) != 1 || st.Level != 0 {
		t.Fatalf("submit: %+v %v", st, err)
	}
	if _, err := f.svc.Decide(ctx, f.id, "nid", actor, false, "x"); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal("short reason accepted")
	}
	if _, err := f.svc.Decide(ctx, f.id, "selfie", actor, false, "Blurred photo"); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveSelfie(ctx, f.id, uuid.New()); err != nil {
		t.Fatal(err)
	}
	approveAll(t, f, actor)
	if lvl, _ := f.svc.Level(ctx, f.id); lvl != 1 {
		t.Fatalf("level %d", lvl)
	}
	if ok, _ := f.svc.CanReceiveBookings(ctx, f.id, uuid.Nil); !ok {
		t.Fatal("level 1 cannot receive bookings")
	}
	if ok, _ := f.svc.CanReceiveBookings(ctx, f.id, uuid.New()); !ok {
		t.Fatal("level 1 service")
	}
	levels, _ := f.svc.Levels(ctx, []uuid.UUID{f.id})
	review, err := f.svc.Review(ctx, f.id)
	if levels[f.id] != 1 || err != nil || review.NIDNumber != "1234567890" || review.Provider.FullName != "Rahim" {
		t.Fatalf("review: %+v %v", review, err)
	}
	var approved, rejected, changed int
	for _, e := range f.repo.events {
		switch e.(type) {
		case contract.DocumentApproved:
			approved++
		case contract.DocumentRejected:
			rejected++
		case contract.ProviderLevelChanged:
			changed++
		}
	}
	if approved != 8 || rejected != 1 || changed != 1 {
		t.Fatalf("events: %d %d %d", approved, rejected, changed)
	}
	if err := f.svc.OnStepSaved(ctx, f.id, provider.StepPersonal); err != nil {
		t.Fatal(err)
	}
	if st, _ := f.svc.Status(ctx, f.id); st.Level != 0 || st.Item("nid").Status != domain.Pending || st.Item("address").Status != domain.Pending {
		t.Fatal("changed profile kept the level")
	}
	if err := f.svc.OnStepSaved(ctx, f.id, "selfie"); err != nil {
		t.Fatal("document step event")
	}
}

func TestFlow_Rejections(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	if _, err := f.svc.SaveNID(ctx, f.id, "12", uuid.New(), uuid.New()); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	f.repo.blocked["h:9999999999"] = true
	if _, err := f.svc.SaveNID(ctx, f.id, "9999999999", uuid.New(), uuid.New()); !errors.Is(err, domain.ErrNIDBlocked) {
		t.Fatal(err)
	}
	if _, err := f.svc.SavePoliceClearance(ctx, f.id, uuid.New(), f.clock.Now().AddDate(-2, 0, 0)); !errors.Is(err, domain.ErrClearanceTooOld) {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveSkillProof(ctx, f.id, nil); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	f.peers.mediaErr = domain.ErrBadDocument
	if _, err := f.svc.SaveSelfie(ctx, f.id, uuid.New()); !errors.Is(err, domain.ErrBadDocument) {
		t.Fatal(err)
	}
	f.peers.mediaErr, f.peers.submitErr = nil, domain.ErrEnrolmentPending
	if _, err := f.svc.Submit(ctx, f.id); !errors.Is(err, domain.ErrEnrolmentPending) {
		t.Fatal(err)
	}
	if _, err := f.svc.Decide(ctx, f.id, "nid", uuid.New(), true, ""); !errors.Is(err, domain.ErrNotPending) {
		t.Fatal(err)
	}
	if _, err := f.svc.Review(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal(err)
	}
	if err := f.svc.OnStepSaved(ctx, uuid.New(), provider.StepArea); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal(err)
	}
}

func TestFlow_StoreFailures(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	enrolled(t, f)
	f.svc.d.Cipher = fakeCipher{broken: true}
	if _, err := f.svc.Review(ctx, f.id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.repo.err = errBoom
	for _, call := range []func() error{
		func() error { _, err := f.svc.SaveNID(ctx, f.id, "1234567890", uuid.New(), uuid.New()); return err },
		func() error { _, err := f.svc.SaveSelfie(ctx, f.id, uuid.New()); return err },
		func() error { _, err := f.svc.Status(ctx, f.id); return err },
		func() error { _, err := f.svc.Submit(ctx, f.id); return err },
		func() error { _, err := f.svc.Decide(ctx, f.id, "nid", uuid.New(), true, ""); return err },
		func() error { _, err := f.svc.CanReceiveBookings(ctx, f.id, uuid.Nil); return err },
		func() error { return f.svc.OnAccountStatus(ctx, f.id, "banned") },
	} {
		if err := call(); !errors.Is(err, errBoom) {
			t.Errorf("store failure: %v", err)
		}
	}
	f.repo.err, f.peers.err = nil, errBoom
	if _, err := f.svc.SavePoliceClearance(ctx, f.id, uuid.New(), f.clock.Now()); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if _, err := f.svc.Queue(ctx, port.QueueFilter{}, port.Page{}); err != nil {
		t.Fatal(err)
	}
	f.repo.queue = []port.QueueRow{{ProviderID: f.id, SubmittedAt: f.clock.Now().Add(-5 * time.Hour), ServiceIDs: []uuid.UUID{uuid.New()}}}
	if _, err := f.svc.Queue(ctx, port.QueueFilter{}, port.Page{}); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.peers.err = nil
	rows, err := f.svc.Queue(ctx, port.QueueFilter{}, port.Page{})
	if err != nil || rows[0].AgeHours != 5 || rows[0].Name != "Rahim" || len(rows[0].Services) != 1 {
		t.Fatalf("queue: %+v %v", rows, err)
	}
}
