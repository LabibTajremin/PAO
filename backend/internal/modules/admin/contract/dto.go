package contract

import "time"

// Settings are the admin-editable platform rules with the defaults from
// docs/build/04-decisions.md.
type Settings struct {
	// AcceptTimeoutASAP and AcceptTimeoutScheduled are the provider's time to respond (D12).
	AcceptTimeoutASAP      time.Duration
	AcceptTimeoutScheduled time.Duration
	// DefaultSearchRadiusM applies to services without their own radius (D5).
	DefaultSearchRadiusM int
	// RatingFloor and RatingMinJobs flag providers rated below the floor (D13).
	RatingFloor   float64
	RatingMinJobs int
	// MaxProviderCancellations30d flags providers who cancel too often (D13).
	MaxProviderCancellations30d int
	// StartCodeMaxAttempts and StartCodeLockout protect the start code (P07).
	StartCodeMaxAttempts int
	StartCodeLockout     time.Duration
	// PoliceClearanceValidity is how long a certificate counts from its issue date.
	PoliceClearanceValidity time.Duration
	// Level2CoolingOff is the wait before retrying a failed Level 2 session.
	Level2CoolingOff time.Duration
	// DocumentRetention is how long documents are kept after closure (D14).
	DocumentRetention time.Duration
	// ServiceAreaGeoJSON is the launch area polygon (D5); empty means everywhere.
	ServiceAreaGeoJSON string
}
