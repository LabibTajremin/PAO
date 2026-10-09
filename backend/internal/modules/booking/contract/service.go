// Package contract is the booking module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// BookingService is what other modules may ask of the booking module.
type BookingService interface {
	// GetBooking returns a booking with its parties and snapshots, or ErrBookingNotFound.
	GetBooking(ctx context.Context, bookingID uuid.UUID) (Booking, error)
	// CountActiveJobs returns how many accepted-but-unfinished jobs the provider has;
	// the MVP allows one active ASAP job at a time (PRD §5).
	CountActiveJobs(ctx context.Context, providerID uuid.UUID) (int, error)
	// GetProviderStats returns completed jobs and recent provider cancellations, used for
	// search cards and quality thresholds (D13).
	GetProviderStats(ctx context.Context, providerID uuid.UUID) (ProviderStats, error)
	// ListRecentBookings returns a party's latest bookings for admin detail pages.
	ListRecentBookings(ctx context.Context, partyID uuid.UUID, limit int) ([]Summary, error)
}
