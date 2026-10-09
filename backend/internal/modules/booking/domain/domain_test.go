package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

var now = time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)

var states = []string{Requested, Accepted, OnTheWay, Arrived, InProgress, Completed, Rejected, TimedOut, Cancelled}

func TestTransitionMatrix(t *testing.T) {
	allowed := map[[3]string]bool{
		{Requested, Accepted, ByProvider}: true, {Requested, Rejected, ByProvider}: true, {Requested, TimedOut, BySystem}: true,
		{Requested, Cancelled, ByCustomer}: true, {Accepted, OnTheWay, ByProvider}: true, {OnTheWay, Arrived, ByProvider}: true,
		{Arrived, InProgress, ByProvider}: true, {InProgress, Completed, ByProvider}: true,
		{Accepted, Cancelled, ByCustomer}: true, {OnTheWay, Cancelled, ByCustomer}: true, {Arrived, Cancelled, ByCustomer}: true,
		{Accepted, Cancelled, ByProvider}: true, {OnTheWay, Cancelled, ByProvider}: true, {Arrived, Cancelled, ByProvider}: true,
	}
	for _, from := range states {
		for _, to := range states {
			for _, actor := range []string{ByCustomer, ByProvider, BySystem} {
				if got := CanTransition(from, to, actor); got != allowed[[3]string{from, to, actor}] {
					t.Errorf("%s → %s by %s: %v", from, to, actor, got)
				}
			}
		}
	}
}

func booking(status string) *Booking {
	return &Booking{Status: status, AcceptDeadline: now.Add(3 * time.Minute), StartCode: "4821"}
}

func TestAcceptRejectTimeout(t *testing.T) {
	id := uuid.New()
	if err := booking(Requested).Accept(now.Add(3*time.Minute), id); !errors.Is(err, ErrDeadlinePassed) {
		t.Fatal(err)
	}
	busy := booking(Requested)
	busy.ProviderActiveJobs = 1
	if err := busy.Accept(now, id); !errors.Is(err, ErrActiveJob) {
		t.Fatal(err)
	}
	busy.Scheduled = true
	if err := busy.Accept(now, id); err != nil || busy.AcceptedAt == nil || len(busy.NewEvents) != 1 {
		t.Fatal("scheduled booking with an active job")
	}
	if err := busy.Accept(now, id); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	if err := booking(Requested).Reject(now.Add(time.Hour), id, "busy"); !errors.Is(err, ErrDeadlinePassed) {
		t.Fatal(err)
	}
	b := booking(Requested)
	if err := b.Reject(now, id, "busy"); err != nil || b.RejectReason != "busy" {
		t.Fatal(err)
	}
	if err := booking(Accepted).Reject(now, id, "busy"); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	if err := booking(Requested).TimeOut(now, id); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	if err := booking(Requested).TimeOut(now.Add(3*time.Minute), id); err != nil {
		t.Fatal(err)
	}
}

func TestCancel(t *testing.T) {
	id := uuid.New()
	for _, st := range []string{InProgress, Completed} {
		if err := booking(st).Cancel(now, id, ByCustomer, "x"); !errors.Is(err, ErrCancelNotAllowed) {
			t.Fatal(err)
		}
	}
	if err := booking(Requested).Cancel(now, id, ByProvider, "x"); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	b := booking(Accepted)
	b.AcceptedAt = &now
	if !b.Cancellable() || b.Cancel(now, id, ByProvider, "emergency") != nil || !b.AfterAcceptance() || b.CancelledBy != ByProvider || b.Cancellable() {
		t.Fatal("provider cancel")
	}
}

func TestStartCode(t *testing.T) {
	id := uuid.New()
	if err := booking(OnTheWay).Start("4821", now, id, 5, 10*time.Minute); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	b := booking(Arrived)
	for i := 1; i <= 5; i++ {
		if err := b.Start("0000", now, id, 5, 10*time.Minute); !errors.Is(err, ErrCodeWrong) {
			t.Fatal(err)
		}
	}
	if b.CodeLockedUntil == nil || b.CodeAttempts != 0 {
		t.Fatal("not locked after five wrong codes")
	}
	if err := b.Start("4821", now.Add(9*time.Minute), id, 5, 10*time.Minute); !errors.Is(err, ErrCodeLocked) {
		t.Fatal(err)
	}
	if err := b.Start("4821", now.Add(10*time.Minute), id, 5, 10*time.Minute); err != nil || b.Status != InProgress || b.CodeLockedUntil != nil {
		t.Fatal(err)
	}
}

func TestExtrasAndComplete(t *testing.T) {
	id := uuid.New()
	line, _ := NewLine(uuid.New(), uuid.New(), uuid.New(), Text{EN: "Fan"}, "unit", 2, 10, 50000)
	if _, err := NewLine(uuid.New(), uuid.New(), uuid.New(), Text{}, "unit", 11, 10, 1); !errors.Is(err, ErrInvalid) {
		t.Fatal("over max quantity")
	}
	b := booking(Arrived)
	b.Lines, b.TotalPaisa = []Line{line}, line.TotalPaisa
	if err := b.Propose(Proposal{ID: id, Lines: []Line{line}}); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	b.Status = InProgress
	if err := b.Propose(Proposal{ID: id}); !errors.Is(err, ErrInvalid) {
		t.Fatal(err)
	}
	if err := b.Propose(Proposal{ID: id, Lines: []Line{line}}); err != nil || b.Pending().AddedPaisa != 100000 {
		t.Fatal(err)
	}
	if err := b.Propose(Proposal{ID: uuid.New(), Lines: []Line{line}}); !errors.Is(err, ErrExtrasPending) {
		t.Fatal(err)
	}
	if err := b.Complete(true, now, id); !errors.Is(err, ErrExtrasPending) {
		t.Fatal(err)
	}
	if _, err := b.Decide(uuid.New(), true, now); !errors.Is(err, ErrNoProposal) {
		t.Fatal(err)
	}
	if p, err := b.Decide(id, true, now); err != nil || p.Status != "approved" || b.TotalPaisa != 200000 || !b.Lines[1].Extra {
		t.Fatalf("approve: %+v %v", b, err)
	}
	second := uuid.New()
	_ = b.Propose(Proposal{ID: second, Lines: []Line{line}})
	if p, _ := b.Decide(second, false, now); p.Status != "declined" || b.TotalPaisa != 200000 {
		t.Fatal("decline changed the total")
	}
	if err := b.Complete(false, now, id); !errors.Is(err, ErrCashNotConfirmed) {
		t.Fatal(err)
	}
	if err := b.Complete(true, now, id); err != nil || !b.CashReceived || b.CompletedAt == nil {
		t.Fatal(err)
	}
	if err := booking(Accepted).Advance(InProgress, now, id); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	if err := booking(Accepted).Complete(true, now, id); !errors.Is(err, ErrInvalidTransition) {
		t.Fatal(err)
	}
	if err := booking(Accepted).Advance(OnTheWay, now, id); err != nil {
		t.Fatal(err)
	}
}

func TestPeriods(t *testing.T) {
	dhaka := time.FixedZone("BDT", 6*3600)
	thu := time.Date(2026, 10, 8, 0, 0, 0, 0, dhaka)
	if f, to, _ := Period("day", thu); !f.Equal(thu) || !to.Equal(thu) {
		t.Fatal("day")
	}
	f, to, _ := Period("week", thu)
	if f.Weekday() != time.Saturday || f.Day() != 3 || to.Day() != 9 || len(Days(f, to)) != 7 {
		t.Fatalf("week: %v %v", f, to)
	}
	if f, _, _ := Period("week", f); f.Day() != 3 {
		t.Fatal("week starting on Saturday")
	}
	f, to, _ = Period("month", time.Date(2026, 2, 14, 0, 0, 0, 0, dhaka))
	if f.Day() != 1 || to.Day() != 28 {
		t.Fatalf("month: %v %v", f, to)
	}
	if _, _, err := Period("year", thu); !errors.Is(err, ErrInvalid) {
		t.Fatal(err)
	}
}

func TestTotalsAndPending(t *testing.T) {
	b := booking(InProgress)
	if b.Pending() != nil || Total(nil) != 0 {
		t.Fatal("empty")
	}
}
