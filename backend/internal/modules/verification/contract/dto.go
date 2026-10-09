package contract

import (
	"errors"
	"time"
)

// ItemType is one Level 1 requirement from PRD §6.2.
type ItemType string

// Verification items.
const (
	ItemNID              ItemType = "nid"
	ItemSelfie           ItemType = "selfie"
	ItemPoliceClearance  ItemType = "police_clearance"
	ItemAddress          ItemType = "address"
	ItemEmergencyContact ItemType = "emergency_contact"
	ItemSkillProof       ItemType = "skill_proof"
	ItemServiceArea      ItemType = "service_area"
	ItemCodeOfConduct    ItemType = "code_of_conduct"
)

// ErrProviderNotFound is returned when verification has no record of the provider.
var ErrProviderNotFound = errors.New("provider has no verification record")

// Item is one verification requirement as admins see it beside the provider record.
type Item struct {
	Type      ItemType
	Status    string
	Reason    string
	Required  bool
	DecidedAt *time.Time
	ExpiresAt *time.Time
}
