// Package domain holds customer profiles and saved addresses (C-01, C-02).
package domain

import (
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// Customer errors.
var (
	ErrNotFound        = errors.New("customer not found")
	ErrAddressNotFound = errors.New("address not found")
	ErrInvalid         = errors.New("customer details are not valid")
	ErrInvalidPhoto    = errors.New("photo is not a confirmed avatar upload of this customer")
	ErrOutsideCountry  = errors.New("location is outside Bangladesh")
	ErrAddressLimit    = errors.New("address limit reached")
	ErrProfileRequired = errors.New("profile must exist before addresses")
)

// Point is a WGS84 position in decimal degrees.
type Point struct {
	Lat float64
	Lng float64
}

// MaxAddresses caps saved addresses per customer (C-02).
const MaxAddresses = 10

// Customer is a customer profile.
type Customer struct {
	ID           uuid.UUID
	Name         string
	PhotoMediaID *uuid.UUID
	Language     string
	UpdatedAt    time.Time
}

// Validate checks the profile fields.
func (c Customer) Validate() error {
	n := utf8.RuneCountInString(strings.TrimSpace(c.Name))
	if n < 2 || n > 80 || (c.Language != "en" && c.Language != "bn") {
		return ErrInvalid
	}
	return nil
}

// Address is a saved place with a map pin.
type Address struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Label      string
	Line1      string
	Line2      string
	Area       string
	Location   Point
	Default    bool
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

// Validate checks the address fields and that the pin lies in Bangladesh.
func (a Address) Validate() error {
	if a.Label != "home" && a.Label != "office" && a.Label != "other" {
		return ErrInvalid
	}
	if n := utf8.RuneCountInString(strings.TrimSpace(a.Line1)); n < 3 || n > 200 {
		return ErrInvalid
	}
	if utf8.RuneCountInString(a.Line2) > 200 || utf8.RuneCountInString(a.Area) > 80 {
		return ErrInvalid
	}
	if !InBangladesh(a.Location) {
		return ErrOutsideCountry
	}
	return nil
}

// InBangladesh is a bounding-box check: it rejects pins dropped far away (a wrong
// sign or swapped coordinates) without needing the exact border.
func InBangladesh(p Point) bool {
	return p.Lat >= 20.5 && p.Lat <= 26.7 && p.Lng >= 88.0 && p.Lng <= 92.7
}
