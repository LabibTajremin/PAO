package contract

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Gender is recorded during enrolment; home salon uses it (D11).
type Gender string

// Genders.
const (
	GenderFemale Gender = "female"
	GenderMale   Gender = "male"
	GenderOther  Gender = "other"
)

// Provider is the enrolment profile other modules read.
type Provider struct {
	ID               uuid.UUID
	FullName         string
	DateOfBirth      *time.Time
	Gender           Gender
	PresentAddress   string
	PermanentAddress string
	Phone            string
	PhotoMediaID     *uuid.UUID
	ServiceIDs       []uuid.UUID
	ExperienceYears  int
	HomeBase         *geo.Point
	WorkingRadiusM   int
	Language         i18n.Language
	EmergencyContact *EmergencyContact
	SubmittedAt      *time.Time
}

// EmergencyContact is the guarantor from PRD §6.2 item 6.
type EmergencyContact struct {
	Name       string
	Relation   string
	Phone      string
	VerifiedAt *time.Time
}

// SortOrder orders the nearby list after the Level 2 ranking.
type SortOrder string

// Sort orders.
const (
	SortDistance SortOrder = "distance"
	SortRating   SortOrder = "rating"
)

// NearbyQuery asks for providers around a point.
type NearbyQuery struct {
	ServiceID          uuid.UUID
	Point              geo.Point
	RadiusM            int
	WomenProvidersOnly bool
	Sort               SortOrder
	Limit              int
}

// NearbyProvider is one search result.
type NearbyProvider struct {
	ProviderID    uuid.UUID
	Name          string
	PhotoMediaID  *uuid.UUID
	Level         int
	Rating        float64
	RatingCount   int
	CompletedJobs int
	DistanceM     int
}

// ErrProviderNotFound is returned for an unknown provider.
var ErrProviderNotFound = errors.New("provider not found")
