package idgen

import (
	"errors"
	"testing"

	"github.com/google/uuid"
)

func TestV7_IsVersion7AndOrdered(t *testing.T) {
	a, b := V7{}.New(), V7{}.New()
	if a.Version() != 7 || a.String() >= b.String() {
		t.Fatalf("a=%v b=%v", a, b)
	}
}

func TestSequence_ReplaysThenGenerates(t *testing.T) {
	fixed := uuid.MustParse("00000000-0000-7000-8000-000000000001")
	s := &Sequence{IDs: []uuid.UUID{fixed}}
	if s.New() != fixed {
		t.Fatal("first id not replayed")
	}
	if s.New().Version() != 7 {
		t.Fatal("fallback is not v7")
	}
}

func TestV7OrRandom_FallsBackOnEntropyFailure(t *testing.T) {
	id := v7OrRandom(func() (uuid.UUID, error) { return uuid.Nil, errors.New("no entropy") })
	if id.Version() != 4 {
		t.Fatalf("version = %d", id.Version())
	}
}
