package domain

import (
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestComplaint_Validate(t *testing.T) {
	photo := uuid.New()
	ok := Complaint{Reason: "late", Description: "Arrived two hours late.", Photos: []uuid.UUID{photo}}
	if err := ok.Validate(); err != nil {
		t.Fatal(err)
	}
	bad := map[string]Complaint{
		"reason":      {Reason: "rude", Description: ok.Description},
		"short":       {Reason: "late", Description: "  late    "},
		"long":        {Reason: "late", Description: strings.Repeat("x", 1001)},
		"many photos": {Reason: "late", Description: ok.Description, Photos: make([]uuid.UUID, 6)},
		"duplicate":   {Reason: "late", Description: ok.Description, Photos: []uuid.UUID{photo, photo}},
	}
	for name, c := range bad {
		if err := c.Validate(); !errors.Is(err, ErrInvalidComplaint) {
			t.Errorf("%s: %v", name, err)
		}
	}
}

func TestComplaint_Transitions(t *testing.T) {
	now := time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)
	c := Complaint{Status: StatusOpen, Ticket: 42}
	if c.TicketNumber() != "TCK-000042" {
		t.Fatal(c.TicketNumber())
	}
	agent := uuid.New()
	if err := c.Assign(agent, now); err != nil || c.Status != StatusAssigned || *c.AssigneeID != agent {
		t.Fatalf("assign: %v %+v", err, c)
	}
	if err := c.Assign(uuid.New(), now); err != nil {
		t.Fatalf("reassign: %v", err)
	}
	if err := c.Resolve("ok", true, now); !errors.Is(err, ErrInvalidComplaint) {
		t.Fatalf("short note: %v", err)
	}
	if err := c.Resolve("Refund issued to the customer.", true, now); err != nil || c.Status != StatusResolved || !c.Verified || !c.ResolvedAt.Equal(now) {
		t.Fatalf("resolve: %v %+v", err, c)
	}
	if err := c.Resolve("Again and again.", false, now); !errors.Is(err, ErrInvalidTransition) {
		t.Fatalf("resolve twice: %v", err)
	}
	if err := c.Assign(agent, now); !errors.Is(err, ErrInvalidTransition) {
		t.Fatalf("assign resolved: %v", err)
	}
}
