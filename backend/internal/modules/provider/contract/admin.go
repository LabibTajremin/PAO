package contract

import (
	"time"

	"github.com/google/uuid"
)

// ProviderQuery filters the admin provider list (A-05). Empty fields do not filter;
// AfterAt and AfterID continue from the last row of the previous page.
type ProviderQuery struct {
	ID      *uuid.UUID
	Text    string
	Status  string
	Level   *int
	Flagged *bool
	AfterAt *time.Time
	AfterID uuid.UUID
	Limit   int
}

// ProviderRecord is a provider as the admin console lists it. Status is the account
// status, except that an active provider without Level 1 is "pending" (PRD §6.4).
type ProviderRecord struct {
	ID            uuid.UUID
	Name          string
	Phone         string
	Status        string
	Level         int
	ServiceIDs    []uuid.UUID
	Rating        float64
	RatingCount   int
	CompletedJobs int
	Flagged       bool
	FlagReason    string
	Online        bool
	CreatedAt     time.Time
}
