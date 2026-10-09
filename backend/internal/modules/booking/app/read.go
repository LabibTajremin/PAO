package app

import (
	"context"
	"slices"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
)

// Booking returns a booking the party takes part in.
func (s *Service) Booking(ctx context.Context, party, id uuid.UUID) (domain.Booking, error) {
	return s.owned(ctx, id, party)
}

// StartCode returns the code the customer reads to the provider; it exists from
// acceptance until the job starts.
func (s *Service) StartCode(ctx context.Context, customer, id uuid.UUID) (string, error) {
	b, err := s.owned(ctx, id, customer)
	if err == nil && b.Customer.ID != customer {
		err = domain.ErrNotFound
	}
	if err == nil && !slices.Contains([]string{domain.Accepted, domain.OnTheWay, domain.Arrived}, b.Status) {
		err = domain.ErrInvalidTransition
	}
	return b.StartCode, err
}

// Receipt returns a completed booking for its receipt.
func (s *Service) Receipt(ctx context.Context, party, id uuid.UUID) (domain.Booking, error) {
	b, err := s.owned(ctx, id, party)
	if err == nil && b.Status != domain.Completed {
		err = domain.ErrInvalidTransition
	}
	return b, err
}

// tabs maps list tabs to states. Providers see open requests on their own tab; their
// upcoming tab holds accepted jobs only.
var tabs = map[string][]string{
	"requests": {domain.Requested},
	"upcoming": domain.Upcoming,
	"jobs":     domain.Active,
	"past":     {domain.Completed, domain.Rejected, domain.TimedOut, domain.Cancelled},
	"all":      append(slices.Clone(domain.Upcoming), domain.Completed, domain.Rejected, domain.TimedOut, domain.Cancelled),
}

// List returns a party's bookings on a tab, newest first.
func (s *Service) List(ctx context.Context, party uuid.UUID, asProvider bool, tab string, p port.Page) ([]port.Summary, error) {
	if asProvider && tab == "upcoming" {
		tab = "jobs"
	}
	return s.d.Repo.List(ctx, party, asProvider, tabs[tab], p)
}

// Earnings is a provider's totals for a calendar period (P-08).
type Earnings struct {
	From, To time.Time
	Total    int64
	Jobs     int
	Days     []port.DayTotal
}

// Earnings totals completed jobs per Asia/Dhaka day over the period containing day.
func (s *Service) Earnings(ctx context.Context, provider uuid.UUID, period string, day *time.Time) (Earnings, error) {
	d := s.d.Clock.Now().In(s.d.Dhaka)
	if day != nil {
		d = time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, s.d.Dhaka)
	}
	from, to, err := domain.Period(period, d)
	var rows []port.DayTotal
	if err == nil {
		rows, err = s.d.Repo.EarningsByDay(ctx, provider, from, to.AddDate(0, 0, 1))
	}
	if err != nil {
		return Earnings{}, err
	}
	byDay := map[string]port.DayTotal{}
	for _, r := range rows {
		byDay[r.Day.Format(time.DateOnly)] = r
	}
	out := Earnings{From: from, To: to}
	for _, day := range domain.Days(from, to) {
		r := byDay[day.Format(time.DateOnly)]
		r.Day = day
		out.Days, out.Total, out.Jobs = append(out.Days, r), out.Total+r.Total, out.Jobs+r.Jobs
	}
	return out, nil
}

// EarningsJobs lists completed jobs between two Asia/Dhaka dates (inclusive); open ends
// default to the current month.
func (s *Service) EarningsJobs(ctx context.Context, provider uuid.UUID, from, to *time.Time, p port.Page) ([]port.EarningsJob, error) {
	start, end, _ := domain.Period("month", s.d.Clock.Now().In(s.d.Dhaka))
	if from != nil {
		start = time.Date(from.Year(), from.Month(), from.Day(), 0, 0, 0, 0, s.d.Dhaka)
	}
	if to != nil {
		end = time.Date(to.Year(), to.Month(), to.Day(), 0, 0, 0, 0, s.d.Dhaka)
	}
	return s.d.Repo.EarningsJobs(ctx, provider, start, end.AddDate(0, 0, 1), p)
}

// Stats returns completed jobs and provider cancellations after acceptance in 30 days.
func (s *Service) Stats(ctx context.Context, provider uuid.UUID) (completed, cancellations int, err error) {
	return s.d.Repo.Stats(ctx, provider, s.d.Clock.Now().Add(-30*24*time.Hour))
}

// CountActive returns the provider's active jobs.
func (s *Service) CountActive(ctx context.Context, provider uuid.UUID) (int, error) {
	return s.d.Repo.CountActive(ctx, provider)
}

// Get returns any booking (for other modules).
func (s *Service) Get(ctx context.Context, id uuid.UUID) (domain.Booking, error) {
	return s.d.Repo.Get(ctx, id)
}
