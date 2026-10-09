package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
)

func levelOne(t *testing.T) fixture {
	t.Helper()
	f := newFixture()
	enrolled(t, f)
	approveAll(t, f, uuid.New())
	return f
}

func TestLevel2_ScheduleFailRetryPass(t *testing.T) {
	f := levelOne(t)
	ctx := context.Background()
	actor, service := uuid.New(), uuid.New()
	when := f.clock.Now().Add(48 * time.Hour)
	if _, err := f.svc.Schedule(ctx, f.id, service, f.clock.Now().Add(-time.Hour), "Office"); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if _, err := f.svc.Schedule(ctx, uuid.New(), service, when, "Office"); !errors.Is(err, domain.ErrNotEligible) {
		t.Fatal(err)
	}
	s, err := f.svc.Schedule(ctx, f.id, service, when, " PAO office, Gulshan 1 ")
	if err != nil || s.Location != "PAO office, Gulshan 1" {
		t.Fatalf("schedule: %+v %v", s, err)
	}
	st, _ := f.svc.Status(ctx, f.id)
	if st.NextSession == nil || !st.Level2Eligible {
		t.Fatalf("status: %+v", st)
	}
	if _, err := f.svc.RecordResult(ctx, s.ID, actor, domain.Outcome{Result: "fail", Photos: []uuid.UUID{uuid.New()}}); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.Schedule(ctx, f.id, service, when, "Office"); !errors.Is(err, domain.ErrCoolingOff) {
		t.Fatal(err)
	}
	if st, _ := f.svc.Status(ctx, f.id); st.RetryAfter == nil || st.Level2Eligible {
		t.Fatal("cooling-off not shown")
	}
	f.clock.Advance(15 * 24 * time.Hour)
	s, _ = f.svc.Schedule(ctx, f.id, service, f.clock.Now().Add(time.Hour), "Office")
	got, err := f.svc.RecordResult(ctx, s.ID, actor, domain.Outcome{Result: "pass", Checklist: []domain.CheckItem{{Item: "Safe wiring", Passed: true}}})
	if err != nil || got.Result != "pass" || *got.DecidedBy != actor {
		t.Fatalf("pass: %+v %v", got, err)
	}
	if lvl, _ := f.svc.Level(ctx, f.id); lvl != 2 {
		t.Fatalf("level %d", lvl)
	}
	if _, err := f.svc.RecordResult(ctx, s.ID, actor, domain.Outcome{Result: "pass"}); !errors.Is(err, domain.ErrSessionClosed) {
		t.Fatal(err)
	}
	if _, err := f.svc.RecordResult(ctx, uuid.New(), actor, domain.Outcome{Result: "pass"}); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal(err)
	}
	if got, err := f.svc.Session(ctx, s.ID); err != nil || got.ID != s.ID {
		t.Fatal("session")
	}
	if _, err := f.svc.Sessions(ctx, port.SessionFilter{}, port.Page{}); err != nil {
		t.Fatal(err)
	}
	f.peers.err = errBoom
	if _, err := f.svc.Schedule(ctx, f.id, service, f.clock.Now().Add(time.Hour), "Office"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.peers.err, f.peers.mediaErr = nil, domain.ErrBadDocument
	if _, err := f.svc.RecordResult(ctx, s.ID, actor, domain.Outcome{Result: "pass", Photos: []uuid.UUID{uuid.New()}}); !errors.Is(err, domain.ErrBadDocument) {
		t.Fatal(err)
	}
}

func TestExpiry_DropsLevelAndRemindsOnce(t *testing.T) {
	f := levelOne(t)
	ctx := context.Background()
	exp := *f.repo.states[f.id].Items["police_clearance"].ExpiresAt
	f.repo.expiring = []port.ExpiringItem{{ProviderID: f.id, ItemType: "police_clearance", ExpiresAt: exp}}
	for range 2 {
		if err := f.svc.RemindExpiring(ctx); err != nil {
			t.Fatal(err)
		}
	}
	reminders := 0
	for _, e := range f.repo.events {
		if _, ok := e.(contract.DocumentExpiring); ok {
			reminders++
		}
	}
	if reminders != len(ReminderDays) {
		t.Fatalf("reminders: %d", reminders)
	}
	if err := f.svc.ExpireDocuments(ctx); err != nil || f.repo.states[f.id].Level != 1 {
		t.Fatal("expired early")
	}
	f.clock.Set(exp)
	if err := f.svc.ExpireDocuments(ctx); err != nil {
		t.Fatal(err)
	}
	if st := f.repo.states[f.id]; st.Level != 0 || st.Items["police_clearance"].Status != domain.Expired {
		t.Fatalf("after expiry: %+v", st.Items["police_clearance"])
	}
	f.repo.listErr = errBoom
	if f.svc.ExpireDocuments(ctx) == nil || f.svc.RemindExpiring(ctx) == nil {
		t.Fatal("list errors ignored")
	}
	f.repo.listErr, f.repo.err = nil, errBoom
	if f.svc.RemindExpiring(ctx) == nil {
		t.Fatal("reminder error ignored")
	}
}

func TestAccountStatus_BlocksAndBansNID(t *testing.T) {
	f := levelOne(t)
	ctx := context.Background()
	if err := f.svc.OnAccountStatus(ctx, f.id, "suspended"); err != nil {
		t.Fatal(err)
	}
	if ok, _ := f.svc.CanReceiveBookings(ctx, f.id, uuid.Nil); ok {
		t.Fatal("suspended provider can receive bookings")
	}
	if err := f.svc.OnAccountStatus(ctx, f.id, "banned"); err != nil || !f.repo.blocked["h:1234567890"] {
		t.Fatal("ban did not block the NID")
	}
	if err := f.svc.OnAccountStatus(ctx, f.id, "active"); err != nil {
		t.Fatal(err)
	}
	if ok, _ := f.svc.CanReceiveBookings(ctx, f.id, uuid.Nil); !ok {
		t.Fatal("reinstated provider blocked")
	}
	f.peers.err = errBoom
	if _, err := f.svc.CanReceiveBookings(ctx, f.id, uuid.New()); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}
