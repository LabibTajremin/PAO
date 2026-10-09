// Package port declares what the booking use cases need from adapters and other modules.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Change mutates a booking and returns the events to publish with it.
type Change func(b *domain.Booking) ([]eventbus.Event, error)

// Page is a keyset position over (time, id); Limit includes the look-ahead row.
type Page struct {
	At    *time.Time
	ID    uuid.UUID
	Limit int
}

// Summary is a list row.
type Summary struct {
	ID           uuid.UUID
	Number       int64
	Status       string
	ServiceName  domain.Text
	CustomerName string
	ProviderName string
	Scheduled    bool
	ScheduledAt  *time.Time
	TotalPaisa   int64
	CreatedAt    time.Time
}

// DayTotal is one day of earnings.
type DayTotal struct {
	Day   time.Time
	Total int64
	Jobs  int
}

// EarningsJob is one completed job in the earnings list.
type EarningsJob struct {
	ID          uuid.UUID
	Number      int64
	CompletedAt time.Time
	ServiceName domain.Text
	TotalPaisa  int64
}

// Repository stores bookings. Change holds the provider's advisory lock and the
// booking's row lock, so the one-active-job rule and concurrent accepts are decided
// one at a time.
type Repository interface {
	// Create inserts a booking; a repeated idempotency key returns the stored booking
	// and created=false (PRD §9.6).
	// event builds the creation event once the booking number is known.
	Create(ctx context.Context, b domain.Booking, event func(domain.Booking) eventbus.Event) (out domain.Booking, created bool, err error)
	Get(ctx context.Context, id uuid.UUID) (domain.Booking, error)
	Change(ctx context.Context, id uuid.UUID, fn Change) (domain.Booking, error)
	List(ctx context.Context, party uuid.UUID, asProvider bool, statuses []string, p Page) ([]Summary, error)
	Due(ctx context.Context, now time.Time) ([]uuid.UUID, error)
	EarningsByDay(ctx context.Context, provider uuid.UUID, from, to time.Time) ([]DayTotal, error)
	EarningsJobs(ctx context.Context, provider uuid.UUID, from, to time.Time, p Page) ([]EarningsJob, error)
	Stats(ctx context.Context, provider uuid.UUID, since time.Time) (completed, cancellations int, err error)
	CountActive(ctx context.Context, provider uuid.UUID) (int, error)
}

// Price is a sub-service's current price version.
type Price struct {
	SubServiceID   uuid.UUID
	ServiceID      uuid.UUID
	PriceVersionID uuid.UUID
	Name           domain.Text
	Unit           string
	AmountPaisa    int64
	MaxQuantity    int
	Published      bool
}

// Service is the catalog's view of a bookable service.
type Service struct {
	ID                 uuid.UUID
	Name               domain.Text
	Model              string
	SearchRadiusM      int
	WomenProvidersOnly bool
	Published          bool
}

// Catalog reads services and prices.
type Catalog interface {
	Service(ctx context.Context, id uuid.UUID) (Service, error)
	Price(ctx context.Context, subServiceID uuid.UUID) (Price, error)
}

// Customer is the booking-side view of a customer.
type Customer struct {
	Name    string
	Phone   string
	Address domain.Address
}

// Customers reads the customer's profile, phone and saved address.
type Customers interface {
	Customer(ctx context.Context, id, addressID uuid.UUID) (Customer, error)
	Covered(ctx context.Context, p domain.Point) (bool, error)
	Address(ctx context.Context, id, addressID uuid.UUID) (domain.Address, error)
}

// Provider is the booking-side view of a provider.
type Provider struct {
	Name     string
	Phone    string
	Services []uuid.UUID
}

// Providers checks availability and eligibility.
type Providers interface {
	Provider(ctx context.Context, id uuid.UUID) (Provider, error)
	IsAvailable(ctx context.Context, id uuid.UUID) (bool, error)
	CanReceiveBookings(ctx context.Context, id, serviceID uuid.UUID) (bool, error)
}

// Media shows profile photos.
type Media interface {
	URL(ctx context.Context, viewer, id uuid.UUID) (string, error)
}

// Nearby is a provider found for a customer.
type Nearby struct {
	ID            uuid.UUID
	Name          string
	PhotoMediaID  *uuid.UUID
	Level         int
	Rating        float64
	RatingCount   int
	CompletedJobs int
	DistanceM     int
}

// Finder searches online providers.
type Finder interface {
	FindNearby(ctx context.Context, service uuid.UUID, at domain.Point, radiusM int, womenOnly, byRating bool, limit int) ([]Nearby, error)
}

// Rules are the admin-editable booking settings (D12).
type Rules struct {
	AcceptASAP           time.Duration
	AcceptScheduled      time.Duration
	StartCodeMaxAttempts int
	StartCodeLockout     time.Duration
	DefaultRadiusM       int
}

// Settings reads the rules.
type Settings interface {
	Rules(ctx context.Context) (Rules, error)
}
