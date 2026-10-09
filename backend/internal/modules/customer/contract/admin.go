package contract

import (
	"time"

	"github.com/google/uuid"
)

// CustomerQuery filters the admin customer list (A-05). Empty fields do not filter;
// AfterAt and AfterID continue from the last row of the previous page.
type CustomerQuery struct {
	ID      *uuid.UUID
	Text    string
	Status  string
	AfterAt *time.Time
	AfterID uuid.UUID
	Limit   int
}

// CustomerRecord is a customer as the admin console lists it.
type CustomerRecord struct {
	ID        uuid.UUID
	Name      string
	Phone     string
	Status    string
	Bookings  int
	CreatedAt time.Time
}
