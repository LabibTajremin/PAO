package testkit

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Envelope wraps an event as the outbox relay would deliver it.
func (a *API) Envelope(t testing.TB, e eventbus.Event) eventbus.Envelope {
	t.Helper()
	raw, err := json.Marshal(e)
	if err != nil {
		t.Fatal(err)
	}
	return eventbus.Envelope{ID: uuid.New(), Name: e.EventName(), Payload: raw, OccurredAt: a.Clock.Now()}
}

// Deliver dispatches an event to every subscribed handler, failing the test on error.
func (a *API) Deliver(t testing.TB, e eventbus.Event) {
	t.Helper()
	if err := a.Bus.Dispatch(context.Background(), a.Envelope(t, e)); err != nil {
		t.Fatalf("deliver %s: %v", e.EventName(), err)
	}
}
