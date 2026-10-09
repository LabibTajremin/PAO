package eventbus

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Envelope is a stored event as subscribers receive it.
type Envelope struct {
	ID          uuid.UUID
	Module      string
	Name        string
	AggregateID string
	Payload     json.RawMessage
	OccurredAt  time.Time
}

// Decode unmarshals an envelope's payload into the event type T.
func Decode[T Event](env Envelope) (T, error) {
	var e T
	if err := json.Unmarshal(env.Payload, &e); err != nil {
		return e, fmt.Errorf("decode %s %s: %w", env.Name, env.ID, err)
	}
	return e, nil
}

// Handler processes one event. It must be idempotent: delivery is at least once.
type Handler func(ctx context.Context, env Envelope) error

type subscription struct {
	name    string
	handler Handler
}

// Bus routes events to the subscribers registered by modules at start-up. It is
// in-process today; the interface lets a broker replace it (PRD §9.3 rule 5).
type Bus struct {
	subs map[string][]subscription
}

// NewBus returns an empty bus.
func NewBus() *Bus { return &Bus{subs: map[string][]subscription{}} }

// Subscribe registers handler, identified by name, for events called eventName.
func (b *Bus) Subscribe(eventName, name string, handler Handler) {
	b.subs[eventName] = append(b.subs[eventName], subscription{name: name, handler: handler})
}

// Dispatch delivers env to every subscriber and joins their errors; a failure makes
// the relay retry the event for all of them, which idempotent handlers tolerate.
func (b *Bus) Dispatch(ctx context.Context, env Envelope) error {
	var errs []error
	for _, s := range b.subs[env.Name] {
		if err := s.handler(ctx, env); err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", s.name, err))
		}
	}
	return errors.Join(errs...)
}
