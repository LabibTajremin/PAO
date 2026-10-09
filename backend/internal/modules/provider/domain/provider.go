// Package domain holds the provider profile, enrolment steps and search ranking
// (PRD §5, §6).
package domain

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Provider errors.
var (
	ErrNotFound        = errors.New("provider not found")
	ErrInvalid         = errors.New("provider details are not valid")
	ErrTooYoung        = errors.New("providers must be at least 18")
	ErrUnknownService  = errors.New("service is not offered")
	ErrNotVerified     = errors.New("provider cannot receive bookings yet")
	ErrNoServiceArea   = errors.New("service area is not set")
	ErrOffline         = errors.New("provider is offline")
	ErrContactUnproven = errors.New("emergency contact phone is not verified")
	ErrIncomplete      = errors.New("enrolment has open required steps")
	ErrCodeRejected    = errors.New("one-time code is wrong, expired or locked")
	ErrCodeRateLimited = errors.New("too many codes requested")
	ErrInvalidPhoto    = errors.New("photo is not a confirmed avatar upload of this provider")
)

// Point is a WGS84 position in decimal degrees.
type Point struct {
	Lat float64
	Lng float64
}

// EmergencyContact is the guarantor from PRD §6.2 item 6.
type EmergencyContact struct {
	Name       string
	Relation   string
	Phone      string
	VerifiedAt *time.Time
}

// Provider is the enrolment profile plus read-model copies of level, status and rating.
type Provider struct {
	ID               uuid.UUID
	Phone            string
	FullName         string
	DateOfBirth      *time.Time
	Gender           string
	PresentAddress   string
	PermanentAddress string
	Bio              string
	PhotoMediaID     *uuid.UUID
	ExperienceYears  int
	Language         string
	ServiceIDs       []uuid.UUID
	HomeBase         *Point
	WorkingRadiusM   int
	Emergency        EmergencyContact
	CoCVersion       string
	CoCAcceptedAt    *time.Time
	StepsDone        []string
	SubmittedAt      *time.Time
	AccountStatus    string
	Level            int
	RatingAvg        float64
	RatingCount      int
	CompletedJobs    int
	Flagged          bool
	FlagReason       string
	CreatedAt        time.Time
}

// CanGoOnline reports whether presence may be switched on: an active, verified
// provider with a service area (PRD §6.1).
func (p Provider) CanGoOnline() error {
	switch {
	case p.AccountStatus != "active" || p.Level < 1:
		return ErrNotVerified
	case p.HomeBase == nil || len(p.ServiceIDs) == 0:
		return ErrNoServiceArea
	}
	return nil
}

// Badge is the customer-facing label of a level (PRD §6.1).
func Badge(level int) string {
	switch {
	case level >= 2:
		return "verified_pro"
	case level == 1:
		return "verified"
	}
	return "none"
}
