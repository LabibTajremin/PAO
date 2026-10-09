// Package postgres implements the booking repository.
package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the booking schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
	clock  clock.Clock
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer, clk clock.Clock) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w, clock: clk}
}

func timing(b domain.Booking) string {
	if b.Scheduled {
		return "scheduled"
	}
	return "asap"
}

// Create implements port.Repository.
func (r *Repository) Create(ctx context.Context, b domain.Booking, event func(domain.Booking) eventbus.Event) (domain.Booking, bool, error) {
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		var err error
		b.Number, err = q.InsertBooking(ctx, sqlcdb.InsertBookingParams{ID: b.ID, CustomerID: b.Customer.ID, ProviderID: b.Provider.ID,
			ServiceID: b.ServiceID, ServiceNameEn: b.ServiceName.EN, ServiceNameBn: b.ServiceName.BN, ServiceModel: b.ServiceModel,
			CustomerName: b.Customer.Name, CustomerPhone: b.Customer.Phone, ProviderName: b.Provider.Name, ProviderPhone: b.Provider.Phone,
			AddressID: b.Address.ID, AddressArea: b.Address.Area, AddressLine1: b.Address.Line1, AddressLine2: b.Address.Line2,
			Lng: b.Address.Location.Lng, Lat: b.Address.Location.Lat, Note: b.Note, Status: b.Status, Timing: timing(b),
			ScheduledAt: b.ScheduledAt, EndsAt: b.EndsAt, AcceptDeadline: b.AcceptDeadline, TotalPaisa: b.TotalPaisa,
			StartCode: b.StartCode, IdempotencyKey: b.IdempotencyKey, CreatedAt: b.CreatedAt})
		if err == nil {
			err = save(ctx, q, b)
		}
		if err == nil {
			err = r.outbox.Write(ctx, tx, b.ID.String(), event(b))
		}
		return err
	})
	switch {
	case db.IsUniqueViolation(err, "bookings_customer_id_idempotency_key_key"):
		id, err := r.q.BookingIDByKey(ctx, sqlcdb.BookingIDByKeyParams{CustomerID: b.Customer.ID, IdempotencyKey: b.IdempotencyKey})
		var existing domain.Booking
		if err == nil {
			existing, err = r.Get(ctx, id)
		}
		return existing, false, err
	case db.IsUniqueViolation(err, "bookings_one_request_per_pair"):
		return domain.Booking{}, false, domain.ErrDuplicateRequest
	}
	return b, err == nil, err
}

// Get implements port.Repository.
func (r *Repository) Get(ctx context.Context, id uuid.UUID) (domain.Booking, error) {
	return load(ctx, r.q, id)
}

// Change implements port.Repository.
func (r *Repository) Change(ctx context.Context, id uuid.UUID, fn port.Change) (domain.Booking, error) {
	var b domain.Booking
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		provider, err := q.LockBooking(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.ErrNotFound
		}
		if err == nil {
			err = q.LockProvider(ctx, provider)
		}
		if err == nil {
			b, err = load(ctx, q, id)
		}
		var active int64
		if err == nil {
			active, err = q.CountActive(ctx, sqlcdb.CountActiveParams{ProviderID: provider, ExceptID: id})
		}
		b.ProviderActiveJobs = int(active)
		var events []eventbus.Event
		if err == nil {
			events, err = fn(&b)
		}
		if err == nil {
			err = update(ctx, q, b, r.clock.Now())
		}
		for _, e := range events {
			if err == nil {
				err = r.outbox.Write(ctx, tx, id.String(), e)
			}
		}
		return err
	})
	return b, err
}

// List implements port.Repository.
func (r *Repository) List(ctx context.Context, party uuid.UUID, asProvider bool, statuses []string, p port.Page) ([]port.Summary, error) {
	rows, err := r.q.ListBookings(ctx, sqlcdb.ListBookingsParams{AsProvider: asProvider, PartyID: party, Statuses: statuses,
		BeforeAt: p.At, BeforeID: p.ID, MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]port.Summary, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.Summary{ID: row.ID, Number: row.Number, Status: row.Status, ServiceName: domain.Text{EN: row.ServiceNameEn, BN: row.ServiceNameBn},
			CustomerName: row.CustomerName, ProviderName: row.ProviderName, Scheduled: row.Timing == "scheduled", ScheduledAt: row.ScheduledAt,
			TotalPaisa: row.TotalPaisa, CreatedAt: row.CreatedAt})
	}
	return out, err
}

// Due implements port.Repository.
func (r *Repository) Due(ctx context.Context, now time.Time) ([]uuid.UUID, error) {
	return r.q.DueRequests(ctx, now)
}

// EarningsByDay implements port.Repository.
func (r *Repository) EarningsByDay(ctx context.Context, provider uuid.UUID, from, to time.Time) ([]port.DayTotal, error) {
	rows, err := r.q.EarningsByDay(ctx, sqlcdb.EarningsByDayParams{ProviderID: provider, FromAt: &from, UntilAt: &to})
	out := make([]port.DayTotal, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.DayTotal{Day: row.Day, Total: row.Total, Jobs: int(row.Jobs)})
	}
	return out, err
}

// EarningsJobs implements port.Repository.
func (r *Repository) EarningsJobs(ctx context.Context, provider uuid.UUID, from, to time.Time, p port.Page) ([]port.EarningsJob, error) {
	rows, err := r.q.EarningsJobs(ctx, sqlcdb.EarningsJobsParams{ProviderID: provider, FromAt: &from, UntilAt: &to, BeforeAt: p.At,
		BeforeID: p.ID, MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]port.EarningsJob, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.EarningsJob{ID: row.ID, Number: row.Number, CompletedAt: row.CompletedAt,
			ServiceName: domain.Text{EN: row.ServiceNameEn, BN: row.ServiceNameBn}, TotalPaisa: row.TotalPaisa})
	}
	return out, err
}

// Stats implements port.Repository.
func (r *Repository) Stats(ctx context.Context, provider uuid.UUID, since time.Time) (int, int, error) {
	row, err := r.q.ProviderStats(ctx, sqlcdb.ProviderStatsParams{ProviderID: provider, Since: &since})
	return int(row.Completed), int(row.Cancellations), err
}

// CountActive implements port.Repository.
func (r *Repository) CountActive(ctx context.Context, provider uuid.UUID) (int, error) {
	n, err := r.q.CountActive(ctx, sqlcdb.CountActiveParams{ProviderID: provider})
	return int(n), err
}
