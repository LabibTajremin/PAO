// Package inproc implements the booking contract and the request expiry job.
package inproc

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Service adapts the booking use cases to contract.BookingService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.BookingService = (*Service)(nil)

// GetBooking implements contract.BookingService.
func (s *Service) GetBooking(ctx context.Context, id uuid.UUID) (contract.Booking, error) {
	b, err := s.svc.Get(ctx, id)
	if errors.Is(err, domain.ErrNotFound) {
		return contract.Booking{}, errors.Join(contract.ErrBookingNotFound, err)
	}
	return contract.Booking{ID: b.ID, Number: app.Number(b.Number), Status: contract.Status(b.Status), CustomerID: b.Customer.ID,
		ProviderID: b.Provider.ID, ServiceID: b.ServiceID, ServiceName: i18n.Text(b.ServiceName), CustomerName: b.Customer.Name,
		ProviderName: b.Provider.Name, Area: b.Address.Area, TotalPaisa: b.TotalPaisa, CreatedAt: b.CreatedAt, CompletedAt: b.CompletedAt}, err
}

// CountActiveJobs implements contract.BookingService.
func (s *Service) CountActiveJobs(ctx context.Context, provider uuid.UUID) (int, error) {
	return s.svc.CountActive(ctx, provider)
}

// GetProviderStats implements contract.BookingService.
func (s *Service) GetProviderStats(ctx context.Context, provider uuid.UUID) (contract.ProviderStats, error) {
	done, cancels, err := s.svc.Stats(ctx, provider)
	return contract.ProviderStats{CompletedJobs: done, Cancellations30d: cancels}, err
}

// ListRecentBookings implements contract.BookingService; either party's bookings.
func (s *Service) ListRecentBookings(ctx context.Context, party uuid.UUID, limit int) ([]contract.Summary, error) {
	var out []contract.Summary
	for _, asProvider := range []bool{false, true} {
		rows, err := s.svc.List(ctx, party, asProvider, "all", port.Page{Limit: limit})
		if err != nil {
			return nil, err
		}
		for _, r := range rows {
			out = append(out, contract.Summary{ID: r.ID, Number: app.Number(r.Number), Status: contract.Status(r.Status),
				ServiceName: i18n.Text(r.ServiceName), TotalPaisa: r.TotalPaisa, CreatedAt: r.CreatedAt})
		}
	}
	return out, nil
}

// ExpireArgs is the booking.expire_requests job: requests past their deadline time out
// (D12). It runs every few seconds rather than once per booking, so a missed run
// catches up on the next one.
type ExpireArgs struct{}

// Kind implements river.JobArgs.
func (ExpireArgs) Kind() string { return "booking.expire_requests" }

// ExpireWorker runs ExpireArgs.
type ExpireWorker struct {
	river.WorkerDefaults[ExpireArgs]
	svc *app.Service
}

// NewExpireWorker returns the worker.
func NewExpireWorker(svc *app.Service) *ExpireWorker { return &ExpireWorker{svc: svc} }

// Work implements river.Worker.
func (w *ExpireWorker) Work(ctx context.Context, _ *river.Job[ExpireArgs]) error {
	return w.svc.ExpireDue(ctx)
}
