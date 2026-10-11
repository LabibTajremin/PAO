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

func TestDhakaDate_RollsOverAtSixPMUTC(t *testing.T) {
	cases := map[time.Time]time.Time{
		time.Date(2026, 10, 11, 17, 59, 0, 0, time.UTC): time.Date(2026, 10, 11, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 10, 11, 18, 0, 0, 0, time.UTC):  time.Date(2026, 10, 12, 0, 0, 0, 0, time.UTC),
	}
	for at, want := range cases {
		if got := DhakaDate(at); !got.Equal(want) {
			t.Errorf("DhakaDate(%v) = %v, want %v", at, got, want)
		}
	}
}
