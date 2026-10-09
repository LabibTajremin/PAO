// Package domain holds the catalog rules: the Category → Service → Sub-service tree and
// immutable, versioned prices (PRD §4).
package domain

import (
	"errors"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Catalog errors.
var (
	ErrNotFound      = errors.New("catalog item not found")
	ErrInvalid       = errors.New("catalog item invalid")
	ErrPriceNegative = errors.New("price must not be negative")
)

// Name is a text in English and Bangla.
type Name struct {
	EN string `json:"en"`
	BN string `json:"bn"`
}

func (n Name) valid() bool { return strings.TrimSpace(n.EN) != "" && strings.TrimSpace(n.BN) != "" }

// Service models (PRD §4) and price units.
var (
	Models = []string{"on_demand", "duration_hire", "listing", "partner_referral"}
	Units  = []string{"job", "unit", "hour", "day"}
)

// Category groups services.
type Category struct {
	ID        uuid.UUID
	Name      Name
	IconKey   string
	SortOrder int
	Published bool
	Services  []Service
}

// Service is a trade with the rules other modules enforce.
type Service struct {
	ID                 uuid.UUID
	CategoryID         uuid.UUID
	Name               Name
	IconKey            string
	Model              string
	RequiredLevel      int
	SearchRadiusM      int
	WomenProvidersOnly bool
	RequiresLevel2     bool
	Level2Checklist    []Name
	SortOrder          int
	Published          bool
	SubServices        []SubService
}

// SubService is the bookable item with its current price.
type SubService struct {
	ID             uuid.UUID
	ServiceID      uuid.UUID
	Name           Name
	Description    Name
	Inclusions     []Name
	Exclusions     []Name
	Unit           string
	MaxQuantity    int
	SortOrder      int
	Published      bool
	PriceVersionID uuid.UUID
	Price          int64
}

// PriceVersion is one immutable price row.
type PriceVersion struct {
	ID            uuid.UUID
	SubServiceID  uuid.UUID
	Amount        int64
	EffectiveFrom time.Time
	CreatedBy     uuid.UUID
}

// Validate checks a category.
func (c Category) Validate() error {
	if !c.Name.valid() || strings.TrimSpace(c.IconKey) == "" {
		return ErrInvalid
	}
	return nil
}

// Validate checks a service's rules.
func (s Service) Validate() error {
	switch {
	case !s.Name.valid(), strings.TrimSpace(s.IconKey) == "", !slices.Contains(Models, s.Model),
		s.RequiredLevel < 0, s.RequiredLevel > 2, s.SearchRadiusM < 500, s.SearchRadiusM > 50000:
		return ErrInvalid
	case s.RequiresLevel2 && s.RequiredLevel < 2:
		// A service that needs Level 2 before the first booking requires level 2 (D7).
		return ErrInvalid
	}
	return nil
}

// Validate checks a sub-service.
func (s SubService) Validate() error {
	if !s.Name.valid() || !slices.Contains(Units, s.Unit) || s.MaxQuantity < 1 {
		return ErrInvalid
	}
	return nil
}

// ValidatePrice checks an amount in paisa.
func ValidatePrice(amount int64) error {
	if amount < 0 {
		return ErrPriceNegative
	}
	return nil
}

// Bookable reports whether customers can book the service model directly; listing and
// partner referral services are shown but not booked (PRD §4).
func (s Service) Bookable() bool { return s.Model == "on_demand" || s.Model == "duration_hire" }

// Published keeps only published categories, services and sub-services.
func Published(tree []Category) []Category {
	out := []Category{}
	for _, c := range tree {
		if !c.Published {
			continue
		}
		services := []Service{}
		for _, s := range c.Services {
			if s.Published {
				s.SubServices = slices.DeleteFunc(slices.Clone(s.SubServices), func(ss SubService) bool { return !ss.Published })
				services = append(services, s)
			}
		}
		c.Services = services
		out = append(out, c)
	}
	return out
}
