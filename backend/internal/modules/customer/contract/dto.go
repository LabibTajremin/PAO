package contract

import (
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Customer is the profile a customer sets up after signing in (C-01).
type Customer struct {
	ID           uuid.UUID
	Name         string
	PhotoMediaID *uuid.UUID
	Language     i18n.Language
}

// Address is a saved place with a map pin (C-02).
type Address struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Label      string
	Line1      string
	Line2      string
	Area       string
	Location   geo.Point
}

// Errors returned through the contract.
var (
	ErrCustomerNotFound = errors.New("customer not found")
	ErrAddressNotFound  = errors.New("address not found")
)
