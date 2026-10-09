// Package clock provides the injectable time source used instead of time.Now, so tests
// control time (01-conventions.md §4).
package clock

import (
	"sync"
	"time"
)

// Clock reports the current time.
type Clock interface {
	Now() time.Time
}

// System is the real clock, in UTC.
type System struct{}

// Now returns the current UTC time.
func (System) Now() time.Time { return time.Now().UTC() }

// Fake is a manually advanced clock for tests.
type Fake struct {
	mu  sync.Mutex
	now time.Time
}

// NewFake returns a fake clock set to t.
func NewFake(t time.Time) *Fake { return &Fake{now: t.UTC()} }

// Now returns the fake time.
func (f *Fake) Now() time.Time {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.now
}

// Advance moves the fake time forward by d.
func (f *Fake) Advance(d time.Duration) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.now = f.now.Add(d)
}

// Set moves the fake time to t.
func (f *Fake) Set(t time.Time) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.now = t.UTC()
}

// Dhaka is Asia/Dhaka (UTC+6, no DST), used for calendar boundaries (04-decisions E8).
var Dhaka = time.FixedZone("Asia/Dhaka", 6*60*60)
