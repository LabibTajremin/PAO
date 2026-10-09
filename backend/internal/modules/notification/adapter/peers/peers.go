// Package peers adapts other modules' contracts to the notification ports.
package peers

import (
	"context"

	"github.com/google/uuid"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
)

// Languages implements port.Languages from the customer and provider profiles.
type Languages struct {
	Customers customer.CustomerService
	Providers provider.ProviderService
}

// Language implements port.Languages; Bangla is the default (04-decisions.md).
func (l Languages) Language(ctx context.Context, id uuid.UUID, app string) string {
	if app == "customer" {
		if c, err := l.Customers.GetCustomer(ctx, id); err == nil {
			return string(c.Language)
		}
		return "bn"
	}
	if p, err := l.Providers.GetProvider(ctx, id); err == nil {
		return string(p.Language)
	}
	return "bn"
}

// Bookings implements port.Bookings.
type Bookings struct{ Svc booking.BookingService }

// Booking implements port.Bookings.
func (b Bookings) Booking(ctx context.Context, id uuid.UUID) (port.Booking, error) {
	got, err := b.Svc.GetBooking(ctx, id)
	return port.Booking{Number: got.Number, ServiceEN: got.ServiceName.EN, ServiceBN: got.ServiceName.BN, Area: got.Area,
		ProviderName: got.ProviderName, CustomerName: got.CustomerName}, err
}
