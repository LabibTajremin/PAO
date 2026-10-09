// Package peers adapts other modules' contracts to the admin ports.
package peers

import (
	"context"
	"errors"
	"slices"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
)

// BookingReader is the part of the booking contract complaints need; the booking module
// is built after admin, so the composition root passes a forwarder.
type BookingReader interface {
	GetBooking(ctx context.Context, bookingID uuid.UUID) (booking.Booking, error)
}

// Bookings implements port.Bookings.
type Bookings struct{ Svc BookingReader }

// Parties implements port.Bookings.
func (b Bookings) Parties(ctx context.Context, id uuid.UUID) (customerID, providerID uuid.UUID, err error) {
	got, err := b.Svc.GetBooking(ctx, id)
	if errors.Is(err, booking.ErrBookingNotFound) {
		err = domain.ErrBookingNotFound
	}
	return got.CustomerID, got.ProviderID, err
}

// Media implements port.Media.
type Media struct{ Svc media.MediaService }

// AttachComplaintPhotos implements port.Media.
func (m Media) AttachComplaintPhotos(ctx context.Context, owner uuid.UUID, ids []uuid.UUID) error {
	for _, id := range ids {
		o, err := m.Svc.GetObject(ctx, id)
		if errors.Is(err, media.ErrNotFound) || (err == nil && (o.OwnerID != owner || o.Purpose != media.PurposeComplaintPhoto || !o.Confirmed)) {
			err = domain.ErrInvalidPhoto
		}
		if err != nil {
			return err
		}
	}
	errs := make([]error, 0, len(ids))
	for _, id := range ids {
		errs = append(errs, m.Svc.MarkAttached(ctx, id))
	}
	return errors.Join(errs...)
}

// Admins implements port.Admins.
type Admins struct{ Svc identity.IdentityService }

// CanWorkComplaints implements port.Admins.
func (a Admins) CanWorkComplaints(ctx context.Context, id uuid.UUID) (bool, error) {
	acc, err := a.Svc.GetAccount(ctx, id)
	if errors.Is(err, identity.ErrAccountNotFound) {
		return false, nil
	}
	ok := acc.Status == identity.StatusActive &&
		(slices.Contains(acc.Roles, identity.RoleSupportAgent) || slices.Contains(acc.Roles, identity.RoleSuperAdmin))
	return ok, err
}
