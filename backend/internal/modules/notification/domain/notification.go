package domain

import (
	"time"

	"github.com/google/uuid"
)

// Notification is one inbox entry.
type Notification struct {
	ID          uuid.UUID
	RecipientID uuid.UUID
	App         string
	Type        string
	Title       string
	Body        string
	BookingID   *uuid.UUID
	DedupeKey   string
	Read        bool
	CreatedAt   time.Time
}

// Push is what a device receives.
type Push struct {
	Title string
	Body  string
	Data  map[string]string
}
