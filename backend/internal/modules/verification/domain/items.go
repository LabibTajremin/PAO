// Package domain holds the verification items, level rules and Level 2 sessions
// (PRD §6.1–6.4).
package domain

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Verification errors.
var (
	ErrNotFound         = errors.New("verification record not found")
	ErrInvalid          = errors.New("verification details are not valid")
	ErrNotPending       = errors.New("item is not waiting for a decision")
	ErrClearanceTooOld  = errors.New("police clearance was issued too long ago")
	ErrNIDBlocked       = errors.New("this NID belongs to a banned identity")
	ErrBadDocument      = errors.New("document is not a confirmed upload of the right kind")
	ErrNotEligible      = errors.New("provider is not eligible for Level 2")
	ErrCoolingOff       = errors.New("provider must wait before retrying Level 2")
	ErrSessionClosed    = errors.New("session already has a result")
	ErrEnrolmentPending = errors.New("enrolment has open required steps")
)

// Item statuses.
const (
	Missing  = "missing"
	Pending  = "pending"
	Approved = "approved"
	Rejected = "rejected"
	Expired  = "expired"
)

// Types lists every item in display order; skill proof is optional (PRD §6.2).
var Types = []string{"nid", "selfie", "police_clearance", "address", "emergency_contact", "skill_proof", "service_area", "code_of_conduct"}

// Required reports whether Level 1 needs the item approved.
func Required(itemType string) bool { return itemType != "skill_proof" }

// Item is one requirement's review state.
type Item struct {
	Type        string
	Status      string
	Reason      string
	Fields      map[string]string
	SubmittedAt *time.Time
	DecidedAt   *time.Time
	DecidedBy   *uuid.UUID
	ExpiresAt   *time.Time
}

// Submit puts the item back in the review queue with new data.
func (i *Item) Submit(now time.Time, fields map[string]string, expiresAt *time.Time) {
	i.Status, i.Reason, i.Fields, i.SubmittedAt = Pending, "", fields, &now
	i.DecidedAt, i.DecidedBy, i.ExpiresAt = nil, nil, expiresAt
}

// Decide approves or rejects a pending item; approved items may also be rejected
// when a verifier finds a problem later.
func (i *Item) Decide(now time.Time, actor uuid.UUID, approve bool, reason string) error {
	if i.Status != Pending && (approve || i.Status != Approved) {
		return ErrNotPending
	}
	i.Status, i.Reason, i.DecidedAt, i.DecidedBy = Rejected, reason, &now, &actor
	if approve {
		i.Status, i.Reason = Approved, ""
	}
	return nil
}

// Expire marks an approved item whose validity ended (PRD §6.4).
func (i *Item) Expire(now time.Time) bool {
	if i.Status != Approved || i.ExpiresAt == nil || i.ExpiresAt.After(now) {
		return false
	}
	i.Status = Expired
	return true
}

// Level computes the level: 1 when every required item is approved, 2 when Level 2 was
// also passed (PRD §6.1).
func Level(items map[string]Item, level2Passed bool) int {
	for _, t := range Types {
		if Required(t) && items[t].Status != Approved {
			return 0
		}
	}
	if level2Passed {
		return 2
	}
	return 1
}

// ClearanceExpiry checks a police clearance issue date and returns when the
// certificate stops counting (issue date plus validity).
func ClearanceExpiry(issued, today time.Time, validity time.Duration) (time.Time, error) {
	expires := issued.Add(validity)
	if issued.After(today) || !expires.After(today) {
		return time.Time{}, ErrClearanceTooOld
	}
	return expires, nil
}

// ValidNID accepts the 10, 13 and 17 digit NID formats.
func ValidNID(n string) bool {
	if len(n) != 10 && len(n) != 13 && len(n) != 17 {
		return false
	}
	for _, r := range n {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}
