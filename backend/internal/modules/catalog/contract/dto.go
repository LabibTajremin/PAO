package contract

import (
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// ServiceModel says how a service books (PRD §4).
type ServiceModel string

// Service models.
const (
	ModelOnDemand        ServiceModel = "on_demand"
	ModelDurationHire    ServiceModel = "duration_hire"
	ModelListing         ServiceModel = "listing"
	ModelPartnerReferral ServiceModel = "partner_referral"
)

// PriceUnit is what one quantity of a sub-service means.
type PriceUnit string

// Price units.
const (
	UnitJob  PriceUnit = "job"
	UnitUnit PriceUnit = "unit"
	UnitHour PriceUnit = "hour"
	UnitDay  PriceUnit = "day"
)

// Service is a trade within a category, with the rules other modules enforce.
type Service struct {
	ID                 uuid.UUID
	CategoryID         uuid.UUID
	Name               i18n.Text
	Model              ServiceModel
	RequiredLevel      int
	SearchRadiusM      int
	WomenProvidersOnly bool
	RequiresLevel2     bool
	Level2Checklist    []i18n.Text
	Published          bool
}

// PriceSnapshot is the price of one sub-service at a moment, copied onto bookings.
type PriceSnapshot struct {
	SubServiceID   uuid.UUID
	ServiceID      uuid.UUID
	PriceVersionID uuid.UUID
	Name           i18n.Text
	Unit           PriceUnit
	AmountPaisa    int64
	MaxQuantity    int
	Published      bool
}

// Errors returned through the contract.
var (
	ErrServiceNotFound    = errors.New("service not found")
	ErrSubServiceNotFound = errors.New("sub-service not found")
)
