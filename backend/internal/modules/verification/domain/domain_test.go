package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

var now = time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)

func approvedAll() map[string]Item {
	items := map[string]Item{}
	for _, t := range Types {
		if Required(t) {
			items[t] = Item{Type: t, Status: Approved}
		}
	}
	return items
}

func TestLevel(t *testing.T) {
	items := approvedAll()
	if Level(items, false) != 1 || Level(items, true) != 2 {
		t.Fatal("all approved")
	}
	for _, t1 := range Types {
		if !Required(t1) {
			continue
		}
		for _, st := range []string{Missing, Pending, Rejected, Expired} {
			copied := approvedAll()
			copied[t1] = Item{Type: t1, Status: st}
			if Level(copied, true) != 0 {
				t.Errorf("%s %s kept a level", t1, st)
			}
		}
	}
}

func TestItemLifecycle(t *testing.T) {
	actor := uuid.New()
	var it Item
	if it.Decide(now, actor, true, "") != ErrNotPending {
		t.Fatal("missing item approved")
	}
	exp := now.Add(time.Hour)
	it.Submit(now, map[string]string{"issueDate": "2026-06-01"}, &exp)
	if err := it.Decide(now, actor, true, ""); err != nil || it.Status != Approved || *it.DecidedBy != actor {
		t.Fatalf("approve: %+v %v", it, err)
	}
	if it.Decide(now, actor, true, "") != ErrNotPending {
		t.Fatal("approved twice")
	}
	if err := it.Decide(now, actor, false, "fake"); err != nil || it.Status != Rejected || it.Reason != "fake" {
		t.Fatalf("reject approved: %+v %v", it, err)
	}
	if it.Decide(now, actor, false, "again") != ErrNotPending {
		t.Fatal("rejected twice")
	}
	it.Submit(now, nil, &exp)
	_ = it.Decide(now, actor, true, "")
	if it.Expire(now) || !it.Expire(exp) || it.Status != Expired {
		t.Fatal("expiry")
	}
	if (&Item{Status: Approved}).Expire(now) {
		t.Fatal("item without expiry expired")
	}
}

func TestClearanceAndNID(t *testing.T) {
	year := 365 * 24 * time.Hour
	if exp, err := ClearanceExpiry(now.AddDate(0, -6, 0), now, year); err != nil || !exp.After(now) {
		t.Fatal("recent clearance")
	}
	for _, issued := range []time.Time{now.Add(-year), now.Add(24 * time.Hour)} {
		if _, err := ClearanceExpiry(issued, now, year); !errors.Is(err, ErrClearanceTooOld) {
			t.Errorf("%v accepted", issued)
		}
	}
	for n, ok := range map[string]bool{"1234567890": true, "1234567890123": true, "12345678901234567": true, "123456789": false, "123456789x": false} {
		if ValidNID(n) != ok {
			t.Errorf("ValidNID(%s)", n)
		}
	}
}

func TestSessions(t *testing.T) {
	actor := uuid.New()
	s := Session{ID: uuid.New(), Status: "scheduled"}
	if s.Record(now, actor, Outcome{Result: "maybe"}) != ErrInvalid {
		t.Fatal("bad result")
	}
	if err := s.Record(now, actor, Outcome{Result: "fail"}); err != nil || s.Status != "completed" {
		t.Fatal(err)
	}
	if s.Record(now, actor, Outcome{Result: "pass"}) != ErrSessionClosed {
		t.Fatal("recorded twice")
	}
	older := now.Add(-48 * time.Hour)
	sessions := []Session{s, {Result: "fail", DecidedAt: &older}, {Result: "pass", DecidedAt: &now}}
	if r := RetryAfter(sessions, 14*24*time.Hour, now); r == nil || !r.Equal(now.Add(14*24*time.Hour)) {
		t.Fatalf("retry after: %v", r)
	}
	if RetryAfter(sessions, time.Hour, now.Add(2*time.Hour)) != nil || RetryAfter(nil, time.Hour, now) != nil {
		t.Fatal("cooling-off over")
	}
	st := NewState(uuid.New())
	st.Sessions = []Session{s}
	if got, ok := st.Session(s.ID); !ok || got.ID != s.ID {
		t.Fatal("session lookup")
	}
	if _, ok := st.Session(uuid.New()); ok {
		t.Fatal("unknown session")
	}
}

func TestState(t *testing.T) {
	st := NewState(uuid.New())
	if st.Item("nid").Status != Missing || st.CanReceiveBookings(0) {
		t.Fatal("new state")
	}
	st.Items = approvedAll()
	if from, changed := st.Recalc(); from != 0 || !changed || !st.CanReceiveBookings(1) || st.CanReceiveBookings(2) {
		t.Fatal("level 1")
	}
	if _, changed := st.Recalc(); changed {
		t.Fatal("unchanged level reported")
	}
	if st.Item("nid").Status != Approved {
		t.Fatal("stored item")
	}
	st.Blocked = true
	if st.CanReceiveBookings(0) {
		t.Fatal("blocked provider can receive bookings")
	}
}
