package jobs

import (
	"testing"
	"time"
)

func TestDailyAt_NextFiresAtDhakaWallClock(t *testing.T) {
	d := dailyAt{hour: 2, minute: 0}
	// 19:30 UTC is 01:30 in Dhaka: the run is 30 minutes later, the same Dhaka day.
	got := d.Next(time.Date(2026, 10, 9, 19, 30, 0, 0, time.UTC))
	if want := time.Date(2026, 10, 9, 20, 0, 0, 0, time.UTC); !got.Equal(want) {
		t.Fatalf("next = %v, want %v", got, want)
	}
	// Exactly at 02:00 Dhaka the next run is tomorrow.
	got = d.Next(time.Date(2026, 10, 9, 20, 0, 0, 0, time.UTC))
	if want := time.Date(2026, 10, 10, 20, 0, 0, 0, time.UTC); !got.Equal(want) {
		t.Fatalf("next = %v, want %v", got, want)
	}
}

type argsStub struct{}

func (argsStub) Kind() string { return "stub" }

func TestFixedArgs_ReturnsTheSameArgs(t *testing.T) {
	args, opts := fixedArgs(argsStub{})()
	if args.Kind() != "stub" || opts != nil {
		t.Fatalf("args = %v, opts = %v", args, opts)
	}
}
