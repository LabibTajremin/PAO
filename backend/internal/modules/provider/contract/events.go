package contract

import "github.com/google/uuid"

// EnrolmentStep names a wizard step (M05–M13).
type EnrolmentStep string

// Enrolment steps owned by the provider module; document steps belong to verification.
const (
	StepPersonal         EnrolmentStep = "personal"
	StepServices         EnrolmentStep = "services"
	StepArea             EnrolmentStep = "area"
	StepEmergencyContact EnrolmentStep = "emergency_contact"
	StepCodeOfConduct    EnrolmentStep = "code_of_conduct"
)

// EnrolmentStepSaved is published when a provider saves a non-document step, so the
// matching verification item returns to review.
type EnrolmentStepSaved struct {
	ProviderID uuid.UUID
	Step       EnrolmentStep
}

// EventName implements eventbus.Event.
func (EnrolmentStepSaved) EventName() string { return "provider.EnrolmentStepSaved" }

// ProviderFlaggedForReview is published when quality thresholds are crossed (D13).
type ProviderFlaggedForReview struct {
	ProviderID uuid.UUID
	Reason     string
}

// EventName implements eventbus.Event.
func (ProviderFlaggedForReview) EventName() string { return "provider.ProviderFlaggedForReview" }

// ProviderWentOffline is published when a provider leaves presence, including a forced
// offline after heartbeat loss, a ban or an expired document.
type ProviderWentOffline struct {
	ProviderID uuid.UUID
	Reason     string
}

// EventName implements eventbus.Event.
func (ProviderWentOffline) EventName() string { return "provider.ProviderWentOffline" }
