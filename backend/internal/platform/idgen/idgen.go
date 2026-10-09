// Package idgen issues UUIDv7 identifiers (04-decisions.md E3) behind an interface so
// tests can make them deterministic.
package idgen

import "github.com/google/uuid"

// Generator returns new identifiers.
type Generator interface {
	New() uuid.UUID
}

// V7 generates time-ordered UUIDv7 values.
type V7 struct{}

// New returns a fresh UUIDv7.
func (V7) New() uuid.UUID { return v7OrRandom(uuid.NewV7) }

// v7OrRandom falls back to a random v4 only if the entropy source fails, which
// uuid.NewV7 reports as an error; an ID is still unique, just not time-ordered.
func v7OrRandom(newV7 func() (uuid.UUID, error)) uuid.UUID {
	id, err := newV7()
	if err != nil {
		return uuid.New()
	}
	return id
}

// Sequence returns the given IDs in order, then fresh v7 IDs; for tests.
type Sequence struct {
	IDs  []uuid.UUID
	next int
}

// New returns the next queued ID.
func (s *Sequence) New() uuid.UUID {
	if s.next < len(s.IDs) {
		s.next++
		return s.IDs[s.next-1]
	}
	return V7{}.New()
}
