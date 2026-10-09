package clock

import (
	"testing"
	"time"
)

func TestSystem_ReturnsUTC(t *testing.T) {
	if got := (System{}).Now(); got.Location() != time.UTC {
		t.Fatalf("location = %v", got.Location())
	}
}

func TestFake_AdvanceAndSet(t *testing.T) {
	start := time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)
	f := NewFake(start)
	f.Advance(time.Minute)
	if !f.Now().Equal(start.Add(time.Minute)) {
		t.Fatalf("advance: %v", f.Now())
	}
	f.Set(start)
	if !f.Now().Equal(start) {
		t.Fatalf("set: %v", f.Now())
	}
}

func TestDhaka_IsUTCPlusSix(t *testing.T) {
	_, offset := time.Date(2026, 1, 1, 0, 0, 0, 0, Dhaka).Zone()
	if offset != 6*3600 {
		t.Fatalf("offset = %d", offset)
	}
}
